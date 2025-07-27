const { 
    createResponse, 
    getUserInfo,
    isOwner,
    dynamodb 
} = require('/opt/nodejs/utils');

const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const courseId = event.pathParameters.courseId;
        const userInfo = await getUserInfo(event);
        
        // Check if user is the course owner
        const owner = await isOwner(courseId, userInfo.username, process.env.COURSES_TABLE);
        
        if (!owner) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'Only the course owner can view enrollments'
            });
        }
        
        // Query enrollments for the course
        const params = {
            TableName: ENROLLMENTS_TABLE,
            IndexName: 'courseId-studentId-index',
            KeyConditionExpression: 'courseId = :courseId',
            ExpressionAttributeValues: {
                ':courseId': courseId
            }
        };
        
        const result = await dynamodb.query(params).promise();
        
        // Group enrollments by status
        const enrollments = result.Items || [];
        const grouped = {
            pending: [],
            approved: [],
            rejected: []
        };
        
        enrollments.forEach(enrollment => {
            if (grouped[enrollment.status]) {
                grouped[enrollment.status].push(enrollment);
            }
        });
        
        return createResponse(200, {
            courseId,
            enrollments: grouped,
            summary: {
                total: enrollments.length,
                pending: grouped.pending.length,
                approved: grouped.approved.length,
                rejected: grouped.rejected.length
            }
        });
        
    } catch (error) {
        console.error('Error:', error);
        
        return createResponse(500, {
            error: 'Internal Server Error',
            message: 'Failed to list enrollments'
        });
    }
};