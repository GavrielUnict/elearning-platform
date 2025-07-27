const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const cognito = new AWS.CognitoIdentityServiceProvider();

// Standard HTTP response helper
const createResponse = (statusCode, body, headers = {}) => {
    return {
        statusCode,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': true,
            ...headers
        },
        body: JSON.stringify(body)
    };
};

// Extract user info from Cognito authorizer context
const getUserInfo = async (event) => {
    const claims = event.requestContext.authorizer.claims;
    const username = claims['cognito:username'];
    const email = claims.email;
    const groups = claims['cognito:groups'] ? claims['cognito:groups'].split(',') : [];
    
    return {
        username,
        email,
        groups,
        isTeacher: groups.includes('Docenti'),
        isStudent: groups.includes('Studenti')
    };
};

// Check if user owns a course
const isOwner = async (courseId, username, coursesTableName) => {
    const params = {
        TableName: coursesTableName,
        Key: { courseId }
    };
    
    try {
        const result = await dynamodb.get(params).promise();
        return result.Item && result.Item.teacherId === username;
    } catch (error) {
        console.error('Error checking ownership:', error);
        return false;
    }
};

// Check if student is enrolled in course
const isEnrolled = async (studentId, courseId, enrollmentsTableName) => {
    const params = {
        TableName: enrollmentsTableName,
        Key: { studentId, courseId }
    };
    
    try {
        const result = await dynamodb.get(params).promise();
        return result.Item && result.Item.status === 'approved';
    } catch (error) {
        console.error('Error checking enrollment:', error);
        return false;
    }
};

// Generate unique ID
const generateId = () => {
    const timestamp = Date.now().toString(36);
    const randomStr = Math.random().toString(36).substr(2, 9);
    return `${timestamp}-${randomStr}`;
};

// Validate required fields
const validateRequiredFields = (data, requiredFields) => {
    const missingFields = requiredFields.filter(field => !data[field]);
    if (missingFields.length > 0) {
        throw new Error(`Missing required fields: ${missingFields.join(', ')}`);
    }
};

// DynamoDB batch operations helper
const batchGet = async (tableName, keys) => {
    const chunks = [];
    for (let i = 0; i < keys.length; i += 100) {
        chunks.push(keys.slice(i, i + 100));
    }
    
    const results = [];
    for (const chunk of chunks) {
        const params = {
            RequestItems: {
                [tableName]: {
                    Keys: chunk
                }
            }
        };
        
        const response = await dynamodb.batchGet(params).promise();
        results.push(...(response.Responses[tableName] || []));
    }
    
    return results;
};

// Safe JSON parse
const safeJsonParse = (str, defaultValue = null) => {
    try {
        return JSON.parse(str);
    } catch (error) {
        return defaultValue;
    }
};

module.exports = {
    createResponse,
    getUserInfo,
    isOwner,
    isEnrolled,
    generateId,
    validateRequiredFields,
    batchGet,
    safeJsonParse,
    dynamodb,
    cognito
};