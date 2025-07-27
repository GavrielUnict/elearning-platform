import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Chip,
  Grid,
  Alert,
  Tabs,
  Tab,
  Avatar,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Divider,
} from '@mui/material';
import {
  Check as CheckIcon,
  Close as CloseIcon,
  Person as PersonIcon,
} from '@mui/icons-material';
import { enrollmentAPI } from '../../services/api';
import { useCourses } from '../../hooks/useCourses';
import LoadingSpinner from '../common/LoadingSpinner';

const EnrollmentApproval = () => {
  const { data: coursesData, isLoading } = useCourses();
  const [selectedCourse, setSelectedCourse] = useState(null);
  const [enrollments, setEnrollments] = useState({ pending: [], approved: [], rejected: [] });
  const [loadingEnrollments, setLoadingEnrollments] = useState(false);
  const [error, setError] = useState('');
  const [tabValue, setTabValue] = useState(0);

  const courses = coursesData?.data?.courses || [];

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    if (selectedCourse) {
      fetchEnrollments();
    }
  }, [selectedCourse]);

  const fetchEnrollments = async () => {
    setLoadingEnrollments(true);
    setError('');
    try {
      const response = await enrollmentAPI.list(selectedCourse);
      setEnrollments(response.data.enrollments);
    } catch (error) {
      setError('Errore nel caricamento delle iscrizioni');
      console.error('Error fetching enrollments:', error);
    } finally {
      setLoadingEnrollments(false);
    }
  };

  const handleApproval = async (studentId, action) => {
    try {
      await enrollmentAPI.approve(selectedCourse, studentId, action);
      await fetchEnrollments(); // Refresh list
    } catch (error) {
      setError(`Errore durante ${action === 'approve' ? 'l\'approvazione' : 'il rifiuto'}`);
      console.error('Error updating enrollment:', error);
    }
  };

  if (isLoading) return <LoadingSpinner />;

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Gestione Iscrizioni
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Course Selection */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {courses.map((course) => (
          <Grid item xs={12} sm={6} md={4} key={course.courseId}>
            <Card
              sx={{
                cursor: 'pointer',
                border: selectedCourse === course.courseId ? '2px solid' : '1px solid #e0e0e0',
                borderColor: selectedCourse === course.courseId ? 'primary.main' : '#e0e0e0',
              }}
              onClick={() => setSelectedCourse(course.courseId)}
            >
              <CardContent>
                <Typography variant="h6">{course.name}</Typography>
                <Typography variant="body2" color="text.secondary">
                  {course.description}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Enrollments */}
      {selectedCourse && (
        <Card>
          <CardContent>
            <Tabs value={tabValue} onChange={(e, v) => setTabValue(v)} sx={{ mb: 2 }}>
              <Tab 
                label={`In attesa (${enrollments.pending.length})`} 
                icon={<Chip size="small" label={enrollments.pending.length} color="warning" />}
                iconPosition="end"
              />
              <Tab 
                label={`Approvati (${enrollments.approved.length})`}
                icon={<Chip size="small" label={enrollments.approved.length} color="success" />}
                iconPosition="end"
              />
              <Tab 
                label={`Rifiutati (${enrollments.rejected.length})`}
                icon={<Chip size="small" label={enrollments.rejected.length} color="error" />}
                iconPosition="end"
              />
            </Tabs>

            {loadingEnrollments ? (
              <LoadingSpinner />
            ) : (
              <>
                {/* Pending */}
                {tabValue === 0 && (
                  <List>
                    {enrollments.pending.length === 0 ? (
                      <Typography variant="body2" color="text.secondary" textAlign="center">
                        Nessuna richiesta in attesa
                      </Typography>
                    ) : (
                      enrollments.pending.map((enrollment) => (
                        <React.Fragment key={enrollment.studentId}>
                          <ListItem>
                            <ListItemAvatar>
                              <Avatar>
                                <PersonIcon />
                              </Avatar>
                            </ListItemAvatar>
                            <ListItemText
                              primary={enrollment.studentEmail}
                              secondary={`Richiesta: ${new Date(enrollment.requestedAt).toLocaleString()}`}
                            />
                            <ListItemSecondaryAction>
                              <IconButton
                                edge="end"
                                color="success"
                                onClick={() => handleApproval(enrollment.studentId, 'approve')}
                                sx={{ mr: 1 }}
                              >
                                <CheckIcon />
                              </IconButton>
                              <IconButton
                                edge="end"
                                color="error"
                                onClick={() => handleApproval(enrollment.studentId, 'reject')}
                              >
                                <CloseIcon />
                              </IconButton>
                            </ListItemSecondaryAction>
                          </ListItem>
                          <Divider />
                        </React.Fragment>
                      ))
                    )}
                  </List>
                )}

                {/* Approved */}
                {tabValue === 1 && (
                  <List>
                    {enrollments.approved.length === 0 ? (
                      <Typography variant="body2" color="text.secondary" textAlign="center">
                        Nessuno studente approvato
                      </Typography>
                    ) : (
                      enrollments.approved.map((enrollment) => (
                        <React.Fragment key={enrollment.studentId}>
                          <ListItem>
                            <ListItemAvatar>
                              <Avatar sx={{ bgcolor: 'success.main' }}>
                                <PersonIcon />
                              </Avatar>
                            </ListItemAvatar>
                            <ListItemText
                              primary={enrollment.studentEmail}
                              secondary={`Approvato: ${new Date(enrollment.updatedAt).toLocaleString()}`}
                            />
                          </ListItem>
                          <Divider />
                        </React.Fragment>
                      ))
                    )}
                  </List>
                )}

                {/* Rejected */}
                {tabValue === 2 && (
                  <List>
                    {enrollments.rejected.length === 0 ? (
                      <Typography variant="body2" color="text.secondary" textAlign="center">
                        Nessuna richiesta rifiutata
                      </Typography>
                    ) : (
                      enrollments.rejected.map((enrollment) => (
                        <React.Fragment key={enrollment.studentId}>
                          <ListItem>
                            <ListItemAvatar>
                              <Avatar sx={{ bgcolor: 'error.main' }}>
                                <PersonIcon />
                              </Avatar>
                            </ListItemAvatar>
                            <ListItemText
                              primary={enrollment.studentEmail}
                              secondary={`Rifiutato: ${new Date(enrollment.updatedAt).toLocaleString()}`}
                            />
                          </ListItem>
                          <Divider />
                        </React.Fragment>
                      ))
                    )}
                  </List>
                )}
              </>
            )}
          </CardContent>
        </Card>
      )}
    </Box>
  );
};

export default EnrollmentApproval;