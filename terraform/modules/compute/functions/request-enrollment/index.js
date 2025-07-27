const { 
    createResponse, 
    getUserInfo,
    generateId,
    dynamodb 
} = require('/opt/nodejs/utils');

const AWS = require('aws-sdk');
const sns = new AWS.SNS();

const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;
const COURSES_TABLE = process.env.COURSES_TABLE;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const courseId = event.pathParameters.courseId;
        const userInfo = await getUserInfo(event);
        
        // Only students can request enrollment
        if (!userInfo.isStudent) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'Only students can request enrollment'
            });
        }
        
        // Check if course exists
        const courseParams = {
            TableName: COURSES_TABLE,
            Key: { courseId }
        };
        
        const courseResult = await dynamodb.get(courseParams).promise();
        
        if (!courseResult.Item || courseResult.Item.status !== 'active') {
            return createResponse(404, {
                error: 'Not Found',
                message: 'Course not found or not active'
            });
        }
        
        const course = courseResult.Item;
        
        // Check if already enrolled or pending
        const existingParams = {
            TableName: ENROLLMENTS_TABLE,
            Key: {
                studentId: userInfo.username,
                courseId: courseId
            }
        };
        
        const existingResult = await dynamodb.get(existingParams).promise();
        
        if (existingResult.Item) {
            return createResponse(400, {
                error: 'Bad Request',
                message: `Enrollment already ${existingResult.Item.status}`
            });
        }
        
        // Create enrollment request
        const timestamp = new Date().toISOString();
        const enrollment = {
            studentId: userInfo.username,
            studentEmail: userInfo.email,
            courseId: courseId,
            courseName: course.name,
            teacherId: course.teacherId,
            status: 'pending',
            requestedAt: timestamp,
            updatedAt: timestamp
        };
        
        const putParams = {
            TableName: ENROLLMENTS_TABLE,
            Item: enrollment
        };
        
        await dynamodb.put(putParams).promise();
        
        // Send notification to teacher if SNS is configured
        if (SNS_TOPIC_ARN) {
            try {
                const message = {
                    teacherId: course.teacherId,
                    teacherEmail: course.teacherEmail,
                    courseName: course.name,
                    courseId: courseId,
                    studentEmail: userInfo.email,
                    studentName: userInfo.username,
                    requestedAt: timestamp
                };
                
                await sns.publish({
                    TopicArn: SNS_TOPIC_ARN,
                    Subject: `New enrollment request for ${course.name}`,
                    Message: JSON.stringify(message),
                    MessageAttributes: {
                        teacherEmail: {
                            DataType: 'String',
                            StringValue: course.teacherEmail
                        }
                    }
                }).promise();
            } catch (snsError) {
                console.error('SNS notification failed:', snsError);
                // Don't fail the enrollment if notification fails
            }
        }
        
        return createResponse(201, {
            message: 'Enrollment request submitted successfully',
            enrollment
        });
        
    } catch (error) {
        console.error('Error:', error);
        
        return createResponse(500, {
            error: 'Internal Server Error',
            message: 'Failed to request enrollment'
        });
    }
};