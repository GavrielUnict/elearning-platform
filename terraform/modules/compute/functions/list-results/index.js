const { 
    createResponse, 
    getUserInfo,
    dynamodb 
} = require('/opt/nodejs/utils');

const RESULTS_TABLE = process.env.RESULTS_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const userInfo = await getUserInfo(event);
        
        // Students can only see their own results
        if (!userInfo.isStudent) {
            return createResponse(403, {
                error: 'Forbidden',
                message: 'Only students can view quiz results'
            });
        }
        
        // Query results for the student
        const params = {
            TableName: RESULTS_TABLE,
            KeyConditionExpression: 'studentId = :studentId',
            ExpressionAttributeValues: {
                ':studentId': userInfo.username
            },
            ScanIndexForward: false // Sort by timestamp descending (newest first)
        };
        
        const result = await dynamodb.query(params).promise();
        const results = result.Items || [];
        
        // Group results by quiz
        const groupedByQuiz = {};
        
        results.forEach(result => {
            if (!groupedByQuiz[result.quizId]) {
                groupedByQuiz[result.quizId] = {
                    quizId: result.quizId,
                    documentId: result.documentId,
                    courseId: result.courseId,
                    attempts: []
                };
            }
            
            groupedByQuiz[result.quizId].attempts.push({
                score: result.score,
                correctAnswers: result.correctAnswers,
                totalQuestions: result.totalQuestions,
                completedAt: result.completedAt,
                detailedResults: result.detailedResults
            });
        });
        
        // Convert to array and calculate best scores
        const quizResults = Object.values(groupedByQuiz).map(quiz => {
            const bestScore = Math.max(...quiz.attempts.map(a => a.score));
            const averageScore = quiz.attempts.reduce((sum, a) => sum + a.score, 0) / quiz.attempts.length;
            
            return {
                ...quiz,
                bestScore: bestScore,
                averageScore: Math.round(averageScore),
                totalAttempts: quiz.attempts.length,
                lastAttempt: quiz.attempts[0] // Already sorted by newest first
            };
        });
        
        return createResponse(200, {
            results: quizResults,
            summary: {
                totalQuizzesTaken: quizResults.length,
                totalAttempts: results.length,
                overallAverageScore: quizResults.length > 0 ? 
                    Math.round(quizResults.reduce((sum, q) => sum + q.averageScore, 0) / quizResults.length) : 
                    0
            }
        });
        
    } catch (error) {
        console.error('Error:', error);
        
        return createResponse(500, {
            error: 'Internal Server Error',
            message: 'Failed to list results'
        });
    }
};