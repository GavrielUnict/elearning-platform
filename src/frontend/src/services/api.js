import axios from 'axios';
import { Auth } from 'aws-amplify';

const API_URL = process.env.REACT_APP_API_ENDPOINT;

const api = axios.create({
  baseURL: API_URL,
});

// Add auth token to requests
api.interceptors.request.use(async (config) => {
  try {
    const session = await Auth.currentSession();
    const token = session.getIdToken().getJwtToken();
    config.headers.Authorization = `Bearer ${token}`;
  } catch (error) {
    console.error('Error getting auth token:', error);
  }
  return config;
});

// Course APIs
export const courseAPI = {
  list: () => api.get('/courses'),
  create: (data) => api.post('/courses', data),
  get: (courseId) => api.get(`/courses/${courseId}`),
  update: (courseId, data) => api.put(`/courses/${courseId}`, data),
  delete: (courseId) => api.delete(`/courses/${courseId}`),
};

// Enrollment APIs
export const enrollmentAPI = {
  list: (courseId) => api.get(`/courses/${courseId}/enrollments`),
  request: (courseId) => api.post(`/courses/${courseId}/enrollments`),
  approve: (courseId, studentId, action) => 
    api.put(`/courses/${courseId}/enrollments/${studentId}`, { action }),
};

// Document APIs
export const documentAPI = {
  list: (courseId) => api.get(`/courses/${courseId}/documents`),
  getUploadUrl: (courseId, fileName, fileSize) => 
    api.post(`/courses/${courseId}/documents`, { 
      fileName, 
      fileSize, 
      action: 'upload' 
    }),
  getDownloadUrl: (courseId, documentId) =>
    api.get(`/courses/${courseId}/documents/${documentId}`),
  delete: (courseId, documentId) => 
    api.delete(`/courses/${courseId}/documents/${documentId}`),
};

// Quiz APIs
export const quizAPI = {
  get: (courseId, documentId) => 
    api.get(`/courses/${courseId}/documents/${documentId}/quiz`),
  submit: (courseId, documentId, answers) =>
    api.post(`/courses/${courseId}/documents/${documentId}/quiz`, answers),
};

// Results APIs
export const resultsAPI = {
  list: () => api.get('/results'),
};

export default api;