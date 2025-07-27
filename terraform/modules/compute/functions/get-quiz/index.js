const { 
    createResponse, 
    getUserInfo,
    isEnrolled,
    dynamodb 
} = require('/opt/nodejs/utils');

const QUIZZES_TABLE = process.env.QUIZZES_TABLE;
const DOCUMENTS_TABLE = process.env.DOCUMENTS_TABLE;
const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const courseId = event.pathParameters.courseId;
        const documentId = event.pathParameters.documentId;
        const userInfo = await getUserInfo(event);
        
        // Only enrolled students can access quizzes
        if (!userInfo.isStudent) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'Only students can access quizzes'
            });
        }
        
        const enrolled = await isEnrolled(userInfo.username, courseId, ENROLLMENTS_TABLE);
        
        if (!enrolled) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'You must be enrolled in the course to access quizzes'
            });
        }
        
        // Get document to find quiz ID
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
        
        if (!docResult.Item.quizId) {
            return createResponse(404, {
                error: 'Not Found',
                message: 'No quiz available for this document yet'
            });
        }
        
        // Get quiz
        const quizParams = {
            TableName: QUIZZES_TABLE,
            Key: {
                documentId: documentId,
                quizId: docResult.Item.quizId
            }
        };
        
        const quizResult = await dynamodb.get(quizParams).promise();
        
        if (!quizResult.Item) {
            return createResponse(404, {
                error: 'Not Found',
                message: 'Quiz not found'
            });
        }
        
        // Remove correct answers before sending to student
        const questions = quizResult.Item.questions.map(q => ({
            questionId: q.questionId,
            question: q.question,
            options: q.options
            // Omit correctAnswer field
        }));
        
        return createResponse(200, {
            quiz: {
                quizId: quizResult.Item.quizId,
                documentId: quizResult.Item.documentId,
                documentName: docResult.Item.name,
                questions: questions,
                totalQuestions: questions.length
            }
        });
        
    } catch (error) {
        console.error('Error:', error);
        
        return createResponse(500, {
            error: 'Internal Server Error',
            message: 'Failed to get quiz'
        });
    }
};