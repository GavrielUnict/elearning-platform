const { 
    createResponse, 
    getUserInfo,
    isOwner,
    isEnrolled,
    dynamodb 
} = require('/opt/nodejs/utils');

const DOCUMENTS_TABLE = process.env.DOCUMENTS_TABLE;
const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const courseId = event.pathParameters.courseId;
        const userInfo = await getUserInfo(event);
        
        // Check if user has access to course documents
        const owner = await isOwner(courseId, userInfo.username, process.env.COURSES_TABLE);
        const enrolled = userInfo.isStudent ? 
            await isEnrolled(userInfo.username, courseId, ENROLLMENTS_TABLE) : 
            false;
        
        if (!owner && !enrolled) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'You do not have access to this course'
            });
        }
        
        // Query documents for the course
        const params = {
            TableName: DOCUMENTS_TABLE,
            KeyConditionExpression: 'courseId = :courseId',
            ExpressionAttributeValues: {
                ':courseId': courseId
            }
        };
        
        const result = await dynamodb.query(params).promise();
        const documents = result.Items || [];
        
        // Sort by upload date (newest first)
        documents.sort((a, b) => 
            new Date(b.uploadedAt).getTime() - new Date(a.uploadedAt).getTime()
        );
        
        // For students, only show ready documents
        const filteredDocuments = userInfo.isStudent ? 
            documents.filter(doc => doc.status === 'ready') : 
            documents;
        
        return createResponse(200, {
            courseId,
            documents: filteredDocuments,
            count: filteredDocuments.length
        });
        
    } catch (error) {
        console.error('Error:', error);
        
        return createResponse(500, {
            error: 'Internal Server Error',
            message: 'Failed to list documents'
        });
    }
};