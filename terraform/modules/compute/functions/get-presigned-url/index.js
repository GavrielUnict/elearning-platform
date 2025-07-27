const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const { 
    createResponse, 
    getUserInfo,
    isOwner,
    generateId,
    validateRequiredFields,
    dynamodb 
} = require('/opt/nodejs/utils');

const DOCUMENTS_BUCKET = process.env.DOCUMENTS_BUCKET;
const DOCUMENTS_TABLE = process.env.DOCUMENTS_TABLE;
const COURSES_TABLE = process.env.COURSES_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const courseId = event.pathParameters.courseId;
        const userInfo = await getUserInfo(event);
        const body = JSON.parse(event.body);
        
        // Validate input
        validateRequiredFields(body, ['fileName', 'action']);
        
        if (!['upload', 'download'].includes(body.action)) {
            return createResponse(400, {
                error: 'Bad Request',
                message: 'Action must be either "upload" or "download"'
            });
        }
        
        // For upload, only course owner can get URL
        if (body.action === 'upload') {
            const owner = await isOwner(courseId, userInfo.username, COURSES_TABLE);
            
            if (!owner) {
                return createResponse(403, {
                    error: 'Forbidden',
                    message: 'Only the course owner can upload documents'
                });
            }
            
            // Validate file type
            if (!body.fileName.toLowerCase().endsWith('.pdf')) {
                return createResponse(400, {
                    error: 'Bad Request',
                    message: 'Only PDF files are allowed'
                });
            }
            
            // Generate document ID and S3 key
            const documentId = generateId();
            const s3Key = `courses/${courseId}/documents/${documentId}/${body.fileName}`;
            
            // Generate presigned URL for upload
            const uploadUrl = await s3.getSignedUrlPromise('putObject', {
                Bucket: DOCUMENTS_BUCKET,
                Key: s3Key,
                Expires: 3600, // 1 hour
                ContentType: 'application/pdf'
            });
            
            // Save document metadata
            const timestamp = new Date().toISOString();
            const document = {
                courseId,
                documentId,
                name: body.fileName,
                s3Key,
                uploadedBy: userInfo.username,
                uploadedAt: timestamp,
                size: body.fileSize || 0,
                status: 'pending' // Will be 'ready' after processing
            };
            
            await dynamodb.put({
                TableName: DOCUMENTS_TABLE,
                Item: document
            }).promise();
            
            return createResponse(200, {
                message: 'Upload URL generated successfully',
                uploadUrl,
                documentId,
                expiresIn: 3600
            });
            
        } else {
            // For download, check if user has access (owner or enrolled student)
            const owner = await isOwner(courseId, userInfo.username, COURSES_TABLE);
            const enrolled = userInfo.isStudent ? 
                await require('/opt/nodejs/utils').isEnrolled(userInfo.username, courseId, process.env.ENROLLMENTS_TABLE) : 
                false;
            
            if (!owner && !enrolled) {
                return createResponse(403, {
                    error: 'Forbidden',
                    message: 'Access denied to this document'
                });
            }
            
            // Get document details
            const documentId = body.documentId;
            const docParams = {
                TableName: DOCUMENTS_TABLE,
                Key: { courseId, documentId }
            };
            
            const docResult = await dynamodb.get(docParams).promise();
            
            if (!docResult.Item) {
                return createResponse(404, {
                    error: 'Not Found',
                    message: 'Document not found'
                });
            }
            
            // Generate presigned URL for download
            const downloadUrl = await s3.getSignedUrlPromise('getObject', {
                Bucket: DOCUMENTS_BUCKET,
                Key: docResult.Item.s3Key,
                Expires: 3600 // 1 hour
            });
            
            return createResponse(200, {
                message: 'Download URL generated successfully',
                downloadUrl,
                fileName: docResult.Item.name,
                expiresIn: 3600
            });
        }
        
    } catch (error) {
        console.error('Error:', error);
        
        if (error.message.includes('Missing required fields')) {
            return createResponse(400, {
                error: 'Bad Request',
                message: error.message
            });
        }
        
        return createResponse(500, {
            error: 'Internal Server Error',
            message: 'Failed to generate presigned URL'
        });
    }
};