const { ECSClient, RunTaskCommand, DescribeTasksCommand } = require('@aws-sdk/client-ecs');
const { AutoScalingClient, SetDesiredCapacityCommand, DescribeAutoScalingGroupsCommand } = require('@aws-sdk/client-auto-scaling');

const ecs = new ECSClient();
const autoscaling = new AutoScalingClient();

const CLUSTER_NAME = process.env.ECS_CLUSTER_NAME;
const TASK_DEFINITION_ARN = process.env.TASK_DEFINITION_ARN;
const SUBNET_IDS = process.env.SUBNET_IDS.split(',');
const SECURITY_GROUP_ID = process.env.SECURITY_GROUP_ID;
const ASG_NAME = process.env.ASG_NAME;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        // Parse SQS message
        const record = event.Records[0];
        const sqsMessage = JSON.parse(record.body);
        
        // Check if it's a test event
        if (sqsMessage.Event === 's3:TestEvent') {
            console.log('Ignoring S3 test event');
            return {
                statusCode: 200,
                body: JSON.stringify({ message: 'Test event ignored' })
            };
        }
        
        // Parse the actual S3 event from the SQS message
        const s3Records = sqsMessage.Records;
        if (!s3Records || s3Records.length === 0) {
            throw new Error('No S3 records found in message');
        }
        
        const s3Event = s3Records[0];
        const bucket = s3Event.s3.bucket.name;
        const key = decodeURIComponent(s3Event.s3.object.key.replace(/\+/g, ' '));
        
        console.log(`Processing file: ${key} from bucket: ${bucket}`);
        
        // Extract course ID and document ID from S3 key
        // Expected format: courses/{courseId}/documents/{documentId}/{filename}
        const keyParts = key.split('/');
        if (keyParts.length < 5 || keyParts[0] !== 'courses' || keyParts[2] !== 'documents') {
            throw new Error(`Invalid S3 key format: ${key}`);
        }
        
        const courseId = keyParts[1];
        const documentId = keyParts[3];
        
        console.log(`Course ID: ${courseId}, Document ID: ${documentId}`);
        
        // Check if we have ECS instances running
        const asgResponse = await autoscaling.send(new DescribeAutoScalingGroupsCommand({
            AutoScalingGroupNames: [ASG_NAME]
        }));
        
        const asg = asgResponse.AutoScalingGroups[0];
        const currentCapacity = asg.DesiredCapacity;
        
        // Start an instance if none are running
        if (currentCapacity === 0) {
            console.log('Starting ECS instance...');
            await autoscaling.send(new SetDesiredCapacityCommand({
                AutoScalingGroupName: ASG_NAME,
                DesiredCapacity: 1
            }));
            
            // Wait for instance to be ready
            console.log('Waiting for instance to start...');
            await new Promise(resolve => setTimeout(resolve, 90000)); // 90 seconds
        }
        
        // Run ECS task
        const runTaskParams = {
            cluster: CLUSTER_NAME,
            taskDefinition: TASK_DEFINITION_ARN,
            count: 1,
            launchType: 'EC2',
            overrides: {
                containerOverrides: [
                    {
                        name: 'quiz-processor',
                        environment: [
                            {
                                name: 'DOCUMENT_ID',
                                value: documentId
                            },
                            {
                                name: 'COURSE_ID',
                                value: courseId
                            },
                            {
                                name: 'S3_KEY',
                                value: key
                            }
                        ]
                    }
                ]
            }
        };
        
        console.log('Starting ECS task...');
        const runTaskResponse = await ecs.send(new RunTaskCommand(runTaskParams));
        
        if (runTaskResponse.failures && runTaskResponse.failures.length > 0) {
            console.error('Task failures:', runTaskResponse.failures);
            throw new Error('Failed to start ECS task');
        }
        
        console.log('ECS task started:', runTaskResponse.tasks[0].taskArn);
        
        // Schedule instance shutdown after 15 minutes if no other tasks
        setTimeout(async () => {
            try {
                // Describe all tasks in the cluster
                const listTasksResponse = await ecs.send(new DescribeTasksCommand({
                    cluster: CLUSTER_NAME
                }));
                
                const runningTasks = (listTasksResponse.tasks || []).filter(t => 
                    t.lastStatus === 'RUNNING' || t.lastStatus === 'PENDING'
                );
                
                if (runningTasks.length === 0) {
                    console.log('No running tasks, shutting down instance...');
                    await autoscaling.send(new SetDesiredCapacityCommand({
                        AutoScalingGroupName: ASG_NAME,
                        DesiredCapacity: 0
                    }));
                }
            } catch (error) {
                console.error('Error checking tasks:', error);
            }
        }, 900000); // 15 minutes
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Task started successfully',
                taskArn: runTaskResponse.tasks[0].taskArn
            })
        };
        
    } catch (error) {
        console.error('Error:', error);
        throw error; // Let SQS retry
    }
};