const { 
    createResponse, 
    getUserInfo,
    dynamodb 
} = require('/opt/nodejs/utils');

const COURSES_TABLE = process.env.COURSES_TABLE;
const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        // Get user info from Cognito authorizer
        const userInfo = await getUserInfo(event);
        
        let courses = [];
        
        if (userInfo.isTeacher) {
            // Teachers see only their own courses
            const params = {
                TableName: COURSES_TABLE,
                IndexName: 'teacherId-index',
                KeyConditionExpression: 'teacherId = :teacherId',
                ExpressionAttributeValues: {
                    ':teacherId': userInfo.username
                }
            };
            
            const result = await dynamodb.query(params).promise();
            courses = result.Items || [];
            
        } else if (userInfo.isStudent) {
            // Students see all active courses with their enrollment status
            const scanParams = {
                TableName: COURSES_TABLE,
                FilterExpression: '#status = :status',
                ExpressionAttributeNames: {
                    '#status': 'status'
                },
                ExpressionAttributeValues: {
                    ':status': 'active'
                }
            };
            
            const coursesResult = await dynamodb.scan(scanParams).promise();
            const allCourses = coursesResult.Items || [];
            
            // Get student's enrollments
            const enrollmentParams = {
                TableName: ENROLLMENTS_TABLE,
                KeyConditionExpression: 'studentId = :studentId',
                ExpressionAttributeValues: {
                    ':studentId': userInfo.username
                }
            };
            
            const enrollmentsResult = await dynamodb.query(enrollmentParams).promise();
            const enrollments = enrollmentsResult.Items || [];
            
            // Create enrollment map for quick lookup
            const enrollmentMap = {};
            enrollments.forEach(enrollment => {
                enrollmentMap[enrollment.courseId] = enrollment.status;
            });
            
            // Add enrollment status to each course
            courses = allCourses.map(course => ({
                ...course,
                enrollmentStatus: enrollmentMap[course.courseId] || 'not_enrolled'
            }));
        }
        
        return createResponse(200, {
            courses,
            count: courses.length
        });
        
    } catch (error) {
        console.error('Error:', error);
        
        return createResponse(500, {
            error: 'Internal Server Error',
            message: 'Failed to list courses'
        });
    }
};