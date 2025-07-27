import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  CardActions,
  Grid,
  Typography,
  Button,
  Chip,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
} from '@mui/material';
import {
  School as SchoolIcon,
  Login as EnrollIcon,
  CheckCircle as ApprovedIcon,
  HourglassEmpty as PendingIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { useCourses } from '../../hooks/useCourses';
import { enrollmentAPI } from '../../services/api';
import LoadingSpinner from '../common/LoadingSpinner';

const CourseList = ({ showAll = true, quizMode = false }) => {
  const navigate = useNavigate();
  const { data: coursesData, isLoading, refetch } = useCourses();
  const [enrollDialog, setEnrollDialog] = useState(false);
  const [selectedCourse, setSelectedCourse] = useState(null);
  const [enrolling, setEnrolling] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  if (isLoading) return <LoadingSpinner />;

  const courses = coursesData?.data?.courses || [];
  
  // Filter courses based on props
  let filteredCourses = courses;
  if (!showAll) {
    filteredCourses = courses.filter(course => 
      course.enrollmentStatus === 'approved' || course.enrollmentStatus === 'pending'
    );
  }

  const handleEnrollRequest = async () => {
    setEnrolling(true);
    setError('');
    
    try {
      await enrollmentAPI.request(selectedCourse.courseId);
      setSuccess('Richiesta di iscrizione inviata con successo!');
      setEnrollDialog(false);
      await refetch();
    } catch (error) {
      setError('Errore durante la richiesta di iscrizione');
      console.error('Error requesting enrollment:', error);
    } finally {
      setEnrolling(false);
    }
  };

  const getStatusChip = (status) => {
    switch (status) {
      case 'approved':
        return <Chip icon={<ApprovedIcon />} label="Iscritto" color="success" size="small" />;
      case 'pending':
        return <Chip icon={<PendingIcon />} label="In attesa" color="warning" size="small" />;
      case 'rejected':
        return <Chip label="Rifiutato" color="error" size="small" />;
      default:
        return null;
    }
  };

  const handleCourseClick = (course) => {
    if (course.enrollmentStatus === 'approved') {
      if (quizMode) {
        navigate(`/student/course/${course.courseId}?quizMode=true`);
      } else {
        navigate(`/student/course/${course.courseId}`);
      }
    } else {
      setSelectedCourse(course);
      setEnrollDialog(true);
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        {showAll ? 'Corsi Disponibili' : (quizMode ? 'I Miei Quiz' : 'I Miei Corsi')}
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError('')}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess('')}>
          {success}
        </Alert>
      )}

      <Grid container spacing={3}>
        {filteredCourses.map((course) => (
          <Grid item xs={12} sm={6} md={4} key={course.courseId}>
            <Card>
              <CardContent>
                <Box display="flex" justifyContent="space-between" alignItems="start" mb={1}>
                  <SchoolIcon color="primary" />
                  {getStatusChip(course.enrollmentStatus)}
                </Box>
                
                <Typography variant="h5" component="div" gutterBottom>
                  {course.name}
                </Typography>
                
                <Typography variant="body2" color="text.secondary">
                  {course.description}
                </Typography>
                
                <Typography variant="caption" display="block" sx={{ mt: 2 }}>
                  Docente: {course.teacherEmail}
                </Typography>
              </CardContent>
              
              <CardActions>
                {course.enrollmentStatus === 'approved' ? (
                  <Button 
                    size="small" 
                    onClick={() => handleCourseClick(course)}
                    fullWidth
                    variant="contained"
                  >
                    {quizMode ? 'Vedi Quiz' : 'Accedi al Corso'}
                  </Button>
                ) : course.enrollmentStatus === 'pending' ? (
                  <Button size="small" disabled fullWidth>
                    In attesa di approvazione
                  </Button>
                ) : course.enrollmentStatus === 'rejected' ? (
                  <Button size="small" disabled fullWidth color="error">
                    Iscrizione rifiutata
                  </Button>
                ) : (
                  <Button 
                    size="small" 
                    startIcon={<EnrollIcon />}
                    onClick={() => handleCourseClick(course)}
                    fullWidth
                    variant="outlined"
                  >
                    Richiedi Iscrizione
                  </Button>
                )}
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Enrollment Dialog */}
      <Dialog open={enrollDialog} onClose={() => !enrolling && setEnrollDialog(false)}>
        <DialogTitle>Richiesta di Iscrizione</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Vuoi richiedere l'iscrizione al corso "{selectedCourse?.name}"?
            <br /><br />
            Il docente riceverà una notifica e dovrà approvare la tua richiesta 
            prima che tu possa accedere ai contenuti del corso.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEnrollDialog(false)} disabled={enrolling}>
            Annulla
          </Button>
          <Button onClick={handleEnrollRequest} variant="contained" disabled={enrolling}>
            {enrolling ? 'Invio in corso...' : 'Invia Richiesta'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default CourseList;