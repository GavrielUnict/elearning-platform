const { CognitoIdentityProviderClient, AdminAddUserToGroupCommand, AdminUpdateUserAttributesCommand } = require('@aws-sdk/client-cognito-identity-provider');
const cognito = new CognitoIdentityProviderClient();

exports.handler = async (event) => {
    console.log('Post Confirmation Trigger:', JSON.stringify(event, null, 2));
    
    const userPoolId = event.userPoolId;
    const username = event.userName;
    const userAttributes = event.request.userAttributes;
    
    try {
        // Determina il gruppo basandosi sull'attributo role
        const role = userAttributes['custom:role'] || 'studente';
        const groupName = role.toLowerCase() === 'docente' ? 'Docenti' : 'Studenti';
        
        // Aggiungi l'utente al gruppo appropriato
        const addToGroupCommand = new AdminAddUserToGroupCommand({
            GroupName: groupName,
            UserPoolId: userPoolId,
            Username: username
        });
        
        await cognito.send(addToGroupCommand);
        
        console.log(`User ${username} added to group ${groupName}`);
        
        // Aggiorna l'attributo role se non presente
        if (!userAttributes['custom:role']) {
            const updateAttributesCommand = new AdminUpdateUserAttributesCommand({
                UserPoolId: userPoolId,
                Username: username,
                UserAttributes: [
                    {
                        Name: 'custom:role',
                        Value: role
                    }
                ]
            });
            
            await cognito.send(updateAttributesCommand);
            console.log(`User ${username} role attribute updated to ${role}`);
        }
        
        return event;
        
    } catch (error) {
        console.error('Error in post confirmation trigger:', error);
        throw error;
    }
};