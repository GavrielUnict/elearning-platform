const { 
    createResponse, 
    getUserInfo,
    isOwner,
    validateRequiredFields,
    dynamodb 
} = require('/opt/nodejs/utils');

const COURSES_TABLE = process.env.COURSES_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const courseId = event.pathParameters.courseId;
        const httpMethod = event.httpMethod;
        const userInfo = await getUserInfo(event);
        
        // GET: Anyone can view course details
        if (httpMethod === 'GET') {
            const params = {
                TableName: COURSES_TABLE,
                Key: { courseId }
            };
            
            const result = await dynamodb.get(params).promise();
            
            if (!result.Item) {
                return createResponse(404, {
                    error: 'Not Found',
                    message: 'Course not found'
                });
            }
            
            return createResponse(200, {
                course: result.Item
            });
        }
        
        // For PUT and DELETE, only the course owner can perform these actions
        const owner = await isOwner(courseId, userInfo.username, COURSES_TABLE);
        
        if (!owner) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'Only the course owner can perform this action'
            });
        }
        
        // PUT: Update course
        if (httpMethod === 'PUT') {
            const body = JSON.parse(event.body);
            validateRequiredFields(body, ['name', 'description']);
            
            const params = {
                TableName: COURSES_TABLE,
                Key: { courseId },
                UpdateExpression: 'SET #name = :name, description = :description, updatedAt = :updatedAt',
                ExpressionAttributeNames: {
                    '#name': 'name'
                },
                ExpressionAttributeValues: {
                    ':name': body.name,
                    ':description': body.description,
                    ':updatedAt': new Date().toISOString()
                },
                ReturnValues: 'ALL_NEW'
            };
            
            const result = await dynamodb.update(params).promise();
            
            return createResponse(200, {
                message: 'Course updated successfully',
                course: result.Attributes
            });
        }
        
        // DELETE: Delete course
        if (httpMethod === 'DELETE') {
            // Soft delete by updating status
            const params = {
                TableName: COURSES_TABLE,
                Key: { courseId },
                UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt',
                ExpressionAttributeNames: {
                    '#status': 'status'
                },
                ExpressionAttributeValues: {
                    ':status': 'deleted',
                    ':updatedAt': new Date().toISOString()
                },
                ReturnValues: 'ALL_NEW'
            };
            
            await dynamodb.update(params).promise();
            
            return createResponse(200, {
                message: 'Course deleted successfully'
            });
        }
        
        return createResponse(405, {
            error: 'Method Not Allowed',
            message: `Method ${httpMethod} not allowed`
        });
        
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
            message: 'Failed to process request'
        });
    }
};