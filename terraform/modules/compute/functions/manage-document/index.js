const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const { 
    createResponse, 
    getUserInfo,
    isOwner,
    isEnrolled,
    dynamodb 
} = require('/opt/nodejs/utils');

const DOCUMENTS_TABLE = process.env.DOCUMENTS_TABLE;
const DOCUMENTS_BUCKET = process.env.DOCUMENTS_BUCKET;
const COURSES_TABLE = process.env.COURSES_TABLE;
const QUIZZES_TABLE = process.env.QUIZZES_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const courseId = event.pathParameters.courseId;
        const documentId = event.pathParameters.documentId;
        const httpMethod = event.httpMethod;
        const userInfo = await getUserInfo(event);
        
        // GET: Get document details (with download URL)
        if (httpMethod === 'GET') {
            // Check access
            const owner = await isOwner(courseId, userInfo.username, COURSES_TABLE);
            const enrolled = userInfo.isStudent ? 
                await isEnrolled(userInfo.username, courseId, process.env.ENROLLMENTS_TABLE) : 
                false;
            
            if (!owner && !enrolled) {
                return createResponse(403, {
                    error: 'Forbidden',
                    message: 'Access denied to this document'
                });
            }
            
            // Get document
            const params = {
                TableName: DOCUMENTS_TABLE,
                Key: { courseId, documentId }
            };
            
            const result = await dynamodb.get(params).promise();
            
            if (!result.Item) {
                return createResponse(404, {
                    error: 'Not Found',
                    message: 'Document not found'
                });
            }
            
            // Generate download URL
            const downloadUrl = await s3.getSignedUrlPromise('getObject', {
                Bucket: DOCUMENTS_BUCKET,
                Key: result.Item.s3Key,
                Expires: 3600
            });
            
            return createResponse(200, {
                document: result.Item,
                downloadUrl,
                expiresIn: 3600
            });
        }
        
        // DELETE: Delete document (owner only)
        if (httpMethod === 'DELETE') {
            const owner = await isOwner(courseId, userInfo.username, COURSES_TABLE);
            
            if (!owner) {
                return createResponse(403, {
                    error: 'Forbidden',
                    message: 'Only the course owner can delete documents'
                });
            }
            
            // Get document details
            const getParams = {
                TableName: DOCUMENTS_TABLE,
                Key: { courseId, documentId }
            };
            
            const docResult = await dynamodb.get(getParams).promise();
            
            if (!docResult.Item) {
                return createResponse(404, {
                    error: 'Not Found',
                    message: 'Document not found'
                });
            }
            
            // Delete from S3
            try {
                await s3.deleteObject({
                    Bucket: DOCUMENTS_BUCKET,
                    Key: docResult.Item.s3Key
                }).promise();
            } catch (s3Error) {
                console.error('S3 deletion error:', s3Error);
            }
            
            // Delete from DynamoDB
            await dynamodb.delete({
                TableName: DOCUMENTS_TABLE,
                Key: { courseId, documentId }
            }).promise();
            
            // Delete associated quiz if exists
            if (docResult.Item.quizId) {
                try {
                    await dynamodb.delete({
                        TableName: QUIZZES_TABLE,
                        Key: { 
                            documentId: documentId,
                            quizId: docResult.Item.quizId 
                        }
                    }).promise();
                } catch (quizError) {
                    console.error('Quiz deletion error:', quizError);
                }
            }
            
            return createResponse(200, {
                message: 'Document deleted successfully'
            });
        }
        
        return createResponse(405, {
            error: 'Method Not Allowed',
            message: `Method ${httpMethod} not allowed`
        });
        
    } catch (error) {
        console.error('Error:', error);
        
        return createResponse(500, {
            error: 'Internal Server Error',
            message: 'Failed to process document request'
        });
    }
};