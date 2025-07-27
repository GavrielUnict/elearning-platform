const { 
    createResponse, 
    getUserInfo,
    isOwner,
    dynamodb 
} = require('/opt/nodejs/utils');

const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;
const COURSES_TABLE = process.env.COURSES_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const courseId = event.pathParameters.courseId;
        const enrollmentId = event.pathParameters.enrollmentId; // studentId
        const userInfo = await getUserInfo(event);
        const body = JSON.parse(event.body);
        
        // Validate action
        if (!body.action || !['approve', 'reject'].includes(body.action)) {
            return createResponse(400, {
                error: 'Bad Request',
                message: 'Action must be either "approve" or "reject"'
            });
        }
        
        // Check if user owns the course
        const owner = await isOwner(courseId, userInfo.username, COURSES_TABLE);
        
        if (!owner) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'Only the course owner can approve enrollments'
            });
        }
        
        // Get enrollment
        const getParams = {
            TableName: ENROLLMENTS_TABLE,
            Key: {
                studentId: enrollmentId,
                courseId: courseId
            }
        };
        
        const result = await dynamodb.get(getParams).promise();
        
        if (!result.Item) {
            return createResponse(404, {
                error: 'Not Found',
                message: 'Enrollment request not found'
            });
        }
        
        if (result.Item.status !== 'pending') {
            return createResponse(400, {
                error: 'Bad Request',
                message: `Enrollment already ${result.Item.status}`
            });
        }
        
        // Update enrollment status
        const timestamp = new Date().toISOString();
        const newStatus = body.action === 'approve' ? 'approved' : 'rejected';
        
        const updateParams = {
            TableName: ENROLLMENTS_TABLE,
            Key: {
                studentId: enrollmentId,
                courseId: courseId
            },
            UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt, approvedAt = :approvedAt, approvedBy = :approvedBy',
            ExpressionAttributeNames: {
                '#status': 'status'
            },
            ExpressionAttributeValues: {
                ':status': newStatus,
                ':updatedAt': timestamp,
                ':approvedAt': timestamp,
                ':approvedBy': userInfo.username
            },
            ReturnValues: 'ALL_NEW'
        };
        
        const updateResult = await dynamodb.update(updateParams).promise();
        
        return createResponse(200, {
            message: `Enrollment ${body.action}d successfully`,
            enrollment: updateResult.Attributes
        });
        
    } catch (error) {
        console.error('Error:', error);
        
        return createResponse(500, {
            error: 'Internal Server Error',
            message: 'Failed to process enrollment'
        });
    }
};