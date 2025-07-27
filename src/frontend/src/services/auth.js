import { Auth } from 'aws-amplify';

export const authService = {
  async signUp(email, password, name, familyName, role) {
    try {
      const { user } = await Auth.signUp({
        username: email,
        password,
        attributes: {
          email,
          name,
          family_name: familyName,
          'custom:role': role,
        },
      });
      return user;
    } catch (error) {
      console.error('SignUp Error Details:', error);
      throw error;
    }
  },

  async confirmSignUp(email, code) {
    try {
      await Auth.confirmSignUp(email, code);
    } catch (error) {
      throw error;
    }
  },

  async signIn(email, password) {
    try {
      const user = await Auth.signIn(email, password);
      return user;
    } catch (error) {
      console.error('SignIn Error Details:', error);
      throw error;
    }
  },

  async signOut() {
    try {
      await Auth.signOut();
    } catch (error) {
      throw error;
    }
  },

  async forgotPassword(email) {
    try {
      await Auth.forgotPassword(email);
    } catch (error) {
      throw error;
    }
  },

  async forgotPasswordSubmit(email, code, password) {
    try {
      await Auth.forgotPasswordSubmit(email, code, password);
    } catch (error) {
      throw error;
    }
  },

  async getCurrentUser() {
    try {
      const user = await Auth.currentAuthenticatedUser();
      const attributes = await Auth.userAttributes(user);
      
      const role = attributes.find(attr => attr.Name === 'custom:role')?.Value;
      const groups = user.signInUserSession.idToken.payload['cognito:groups'] || [];
      
      return {
        username: user.username,
        email: user.attributes.email,
        name: user.attributes.name,
        familyName: user.attributes.family_name,
        role,
        groups,
        isTeacher: groups.includes('Docenti'),
        isStudent: groups.includes('Studenti'),
      };
    } catch (error) {
      return null;
    }
  },
};