const { 
    createResponse, 
    getUserInfo, 
    generateId, 
    validateRequiredFields,
    dynamodb 
} = require('/opt/nodejs/utils');

const COURSES_TABLE = process.env.COURSES_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        // Get user info from Cognito authorizer
        const userInfo = await getUserInfo(event);
        
        // Only teachers can create courses
        if (!userInfo.isTeacher) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'Only teachers can create courses'
            });
        }
        
        // Parse request body
        const body = JSON.parse(event.body);
        
        // Validate required fields
        validateRequiredFields(body, ['name', 'description']);
        
        // Create course object
        const courseId = generateId();
        const timestamp = new Date().toISOString();
        
        const course = {
            courseId,
            name: body.name,
            description: body.description,
            teacherId: userInfo.username,
            teacherEmail: userInfo.email,
            createdAt: timestamp,
            updatedAt: timestamp,
            status: 'active'
        };
        
        // Save to DynamoDB
        const params = {
            TableName: COURSES_TABLE,
            Item: course
        };
        
        await dynamodb.put(params).promise();
        
        return createResponse(201, {
            message: 'Course created successfully',
            course
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
            message: 'Failed to create course'
        });
    }
};