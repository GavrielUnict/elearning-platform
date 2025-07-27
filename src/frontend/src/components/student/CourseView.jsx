import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Chip,
  Alert,
  Breadcrumbs,
  Link,
  Divider,
} from '@mui/material';
import {
  Download as DownloadIcon,
  Quiz as QuizIcon,
  PictureAsPdf as PdfIcon,
  NavigateNext as NavigateNextIcon,
} from '@mui/icons-material';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { documentAPI, courseAPI } from '../../services/api';
import LoadingSpinner from '../common/LoadingSpinner';

const CourseView = () => {
  const { courseId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const quizMode = new URLSearchParams(location.search).get('quizMode') === 'true';
  
  const [course, setCourse] = useState(null);
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    fetchCourseData();
  }, [courseId]);

  const fetchCourseData = async () => {
    setLoading(true);
    setError('');
    
    try {
      // Fetch course details
      const courseResponse = await courseAPI.get(courseId);
      setCourse(courseResponse.data.course);
      
      // Fetch documents
      const docsResponse = await documentAPI.list(courseId);
      setDocuments(docsResponse.data.documents);
    } catch (error) {
      setError('Errore nel caricamento dei dati del corso');
      console.error('Error fetching course data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDownload = async (document) => {
    try {
      const response = await documentAPI.getDownloadUrl(courseId, document.documentId);
      window.open(response.data.downloadUrl, '_blank');
    } catch (error) {
      setError('Errore durante il download');
      console.error('Error downloading:', error);
    }
  };

  const handleQuizClick = (document) => {
    navigate(`/student/quiz/${courseId}/${document.documentId}`);
  };

  if (loading) return <LoadingSpinner />;

  const documentsWithQuiz = documents.filter(doc => doc.quizId && doc.status === 'ready');

  return (
    <Box>
      {/* Breadcrumbs */}
      <Breadcrumbs 
        separator={<NavigateNextIcon fontSize="small" />} 
        sx={{ mb: 3 }}
      >
        <Link 
          component="button"
          variant="body1"
          onClick={() => navigate('/student')}
          underline="hover"
          color="inherit"
        >
          Dashboard
        </Link>
        <Link
          component="button"
          variant="body1"
          onClick={() => navigate(quizMode ? '/student/quizzes' : '/student/my-courses')}
          underline="hover"
          color="inherit"
        >
          {quizMode ? 'I Miei Quiz' : 'I Miei Corsi'}
        </Link>
        <Typography color="text.primary">{course?.name}</Typography>
      </Breadcrumbs>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Course Info */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h4" gutterBottom>
            {course?.name}
          </Typography>
          <Typography variant="body1" color="text.secondary" paragraph>
            {course?.description}
          </Typography>
          <Typography variant="body2">
            <strong>Docente:</strong> {course?.teacherEmail}
          </Typography>
        </CardContent>
      </Card>

      {/* Documents/Quiz List */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            {quizMode ? 'Quiz Disponibili' : 'Documenti del Corso'}
          </Typography>
          
          <Divider sx={{ mb: 2 }} />
          
          {quizMode ? (
            // Quiz Mode - Show only documents with quiz
            documentsWithQuiz.length === 0 ? (
              <Typography variant="body2" color="text.secondary" textAlign="center">
                Nessun quiz disponibile per questo corso
              </Typography>
            ) : (
              <List>
                {documentsWithQuiz.map((doc) => (
                  <React.Fragment key={doc.documentId}>
                    <ListItem>
                      <QuizIcon sx={{ mr: 2, color: 'primary.main' }} />
                      <ListItemText
                        primary={`Quiz: ${doc.name}`}
                        secondary={`Documento caricato: ${new Date(doc.uploadedAt).toLocaleDateString()}`}
                      />
                      <ListItemSecondaryAction>
                        <Button
                          variant="contained"
                          startIcon={<QuizIcon />}
                          onClick={() => handleQuizClick(doc)}
                        >
                          Inizia Quiz
                        </Button>
                      </ListItemSecondaryAction>
                    </ListItem>
                    <Divider />
                  </React.Fragment>
                ))}
              </List>
            )
          ) : (
            // Document Mode - Show all documents
            documents.length === 0 ? (
              <Typography variant="body2" color="text.secondary" textAlign="center">
                Nessun documento disponibile
              </Typography>
            ) : (
              <List>
                {documents.map((doc) => (
                  <React.Fragment key={doc.documentId}>
                    <ListItem>
                      <PdfIcon sx={{ mr: 2, color: 'error.main' }} />
                      <ListItemText
                        primary={doc.name}
                        secondary={
                          <Box>
                            <Typography variant="caption">
                              Caricato: {new Date(doc.uploadedAt).toLocaleDateString()}
                            </Typography>
                            {doc.quizId && (
                              <Chip
                                icon={<QuizIcon />}
                                label="Quiz disponibile"
                                size="small"
                                color="primary"
                                sx={{ ml: 2 }}
                              />
                            )}
                          </Box>
                        }
                      />
                      <ListItemSecondaryAction>
                        <IconButton
                          edge="end"
                          onClick={() => handleDownload(doc)}
                          sx={{ mr: 1 }}
                        >
                          <DownloadIcon />
                        </IconButton>
                        {doc.quizId && (
                          <Button
                            size="small"
                            variant="outlined"
                            startIcon={<QuizIcon />}
                            onClick={() => handleQuizClick(doc)}
                          >
                            Quiz
                          </Button>
                        )}
                      </ListItemSecondaryAction>
                    </ListItem>
                    <Divider />
                  </React.Fragment>
                ))}
              </List>
            )
          )}
        </CardContent>
      </Card>
    </Box>
  );
};

export default CourseView;