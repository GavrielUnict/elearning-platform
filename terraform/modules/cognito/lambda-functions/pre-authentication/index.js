const { CloudWatchLogsClient, CreateLogStreamCommand, PutLogEventsCommand } = require('@aws-sdk/client-cloudwatch-logs');
const cloudwatchlogs = new CloudWatchLogsClient();

exports.handler = async (event) => {
    console.log('Pre Authentication Trigger:', JSON.stringify(event, null, 2));
    
    const projectName = process.env.PROJECT_NAME || 'elearning';
    const environment = process.env.ENVIRONMENT || 'dev';
    const logGroupName = `/aws/lambda/${projectName}-${environment}-auth-logs`;
    
    const logStreamName = `auth-logs-${new Date().toISOString().split('T')[0]}`;
    const timestamp = Date.now();
    const username = event.userName;
    const userPoolId = event.userPoolId;
    
    try {
        // Log dell'accesso
        const logEntry = {
            timestamp: new Date().toISOString(),
            username: username,
            userPoolId: userPoolId,
            eventType: 'USER_AUTHENTICATION',
            sourceIp: event.request.userContextData?.sourceIp || 'unknown',
            deviceKey: event.request.userContextData?.deviceKey || 'unknown',
            success: true
        };
        
        // Verifica se il log stream esiste, altrimenti crealo
        try {
            const createLogStreamCommand = new CreateLogStreamCommand({
                logGroupName: logGroupName,
                logStreamName: logStreamName
            });
            await cloudwatchlogs.send(createLogStreamCommand);
        } catch (err) {
            // Il log stream potrebbe già esistere, non è un problema
            if (err.name !== 'ResourceAlreadyExistsException') {
                console.error('Error creating log stream:', err);
            }
        }
        
        // Invia il log
        const putLogEventsCommand = new PutLogEventsCommand({
            logGroupName: logGroupName,
            logStreamName: logStreamName,
            logEvents: [
                {
                    message: JSON.stringify(logEntry),
                    timestamp: timestamp
                }
            ]
        });
        
        await cloudwatchlogs.send(putLogEventsCommand);
        
        console.log(`Authentication logged for user ${username}`);
        
        // Ritorna l'evento per continuare il flusso di autenticazione
        return event;
        
    } catch (error) {
        console.error('Error in pre authentication trigger:', error);
        // Non bloccare l'autenticazione se il logging fallisce
        return event;
    }
};