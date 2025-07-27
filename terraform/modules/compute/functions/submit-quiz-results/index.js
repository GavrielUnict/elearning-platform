const { 
    createResponse, 
    getUserInfo,
    isEnrolled,
    validateRequiredFields,
    dynamodb 
} = require('/opt/nodejs/utils');

const RESULTS_TABLE = process.env.RESULTS_TABLE;
const QUIZZES_TABLE = process.env.QUIZZES_TABLE;
const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const courseId = event.pathParameters.courseId;
        const documentId = event.pathParameters.documentId;
        const userInfo = await getUserInfo(event);
        const body = JSON.parse(event.body);
        
        // Validate input
        validateRequiredFields(body, ['quizId', 'answers']);
        
        // Only enrolled students can submit quiz results
        if (!userInfo.isStudent) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'Only students can submit quiz results'
            });
        }
        
        const enrolled = await isEnrolled(userInfo.username, courseId, ENROLLMENTS_TABLE);
        
        if (!enrolled) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'You must be enrolled in the course to submit quiz results'
            });
        }
        
        // Get quiz with correct answers
        const quizParams = {
            TableName: QUIZZES_TABLE,
            Key: {
                documentId: documentId,
                quizId: body.quizId
            }
        };
        
        const quizResult = await dynamodb.get(quizParams).promise();
        
        if (!quizResult.Item) {
            return createResponse(404, {
                error: 'Not Found',
                message: 'Quiz not found'
            });
        }
        
        const quiz = quizResult.Item;
        
        // Calculate score
        let correctAnswers = 0;
        const detailedResults = [];
        
        quiz.questions.forEach(question => {
            const studentAnswer = body.answers[question.questionId];
            const isCorrect = studentAnswer === question.correctAnswer;
            
            if (isCorrect) {
                correctAnswers++;
            }
            
            detailedResults.push({
                questionId: question.questionId,
                question: question.question,
                studentAnswer: studentAnswer || null,
                correctAnswer: question.correctAnswer,
                isCorrect: isCorrect
            });
        });
        
        const score = Math.round((correctAnswers / quiz.questions.length) * 100);
        
        // Save result
        const timestamp = new Date().toISOString();
        const result = {
            studentId: userInfo.username,
            quizIdTimestamp: `${body.quizId}#${timestamp}`,
            quizId: body.quizId,
            documentId: documentId,
            courseId: courseId,
            score: score,
            correctAnswers: correctAnswers,
            totalQuestions: quiz.questions.length,
            answers: body.answers,
            detailedResults: detailedResults,
            completedAt: timestamp
        };
        
        await dynamodb.put({
            TableName: RESULTS_TABLE,
            Item: result
        }).promise();
        
        return createResponse(201, {
            message: 'Quiz results submitted successfully',
            result: {
                score: score,
                correctAnswers: correctAnswers,
                totalQuestions: quiz.questions.length,
                detailedResults: detailedResults,
                completedAt: timestamp
            }
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
            message: 'Failed to submit quiz results'
        });
    }
};