import React, { useState } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  CardActions,
  Grid,
  Typography,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  IconButton,
  Alert,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { useCourses, useCreateCourse, useUpdateCourse, useDeleteCourse } from '../../hooks/useCourses';
import LoadingSpinner from '../common/LoadingSpinner';

const CourseManager = () => {
  const { data: courses, isLoading, error } = useCourses();
  const createCourse = useCreateCourse();
  const updateCourse = useUpdateCourse();
  const deleteCourse = useDeleteCourse();
  
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingCourse, setEditingCourse] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
  });

  const handleOpenDialog = (course = null) => {
    if (course) {
      setEditingCourse(course);
      setFormData({
        name: course.name,
        description: course.description,
      });
    } else {
      setEditingCourse(null);
      setFormData({ name: '', description: '' });
    }
    setDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setEditingCourse(null);
    setFormData({ name: '', description: '' });
  };

  const handleSubmit = async () => {
    try {
      if (editingCourse) {
        await updateCourse.mutateAsync({
          courseId: editingCourse.courseId,
          data: formData,
        });
      } else {
        await createCourse.mutateAsync(formData);
      }
      handleCloseDialog();
    } catch (error) {
      console.error('Error saving course:', error);
    }
  };

  const handleDelete = async (courseId) => {
    if (window.confirm('Sei sicuro di voler eliminare questo corso?')) {
      try {
        await deleteCourse.mutateAsync(courseId);
      } catch (error) {
        console.error('Error deleting course:', error);
      }
    }
  };

  if (isLoading) return <LoadingSpinner />;
  if (error) return <Alert severity="error">Errore nel caricamento dei corsi</Alert>;

  const teacherCourses = courses?.data?.courses || [];

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">I miei corsi</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          Nuovo Corso
        </Button>
      </Box>

      <Grid container spacing={3}>
        {teacherCourses.map((course) => (
          <Grid item xs={12} sm={6} md={4} key={course.courseId}>
            <Card>
              <CardContent>
                <Typography variant="h5" component="div" gutterBottom>
                  {course.name}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {course.description}
                </Typography>
                <Typography variant="caption" display="block" sx={{ mt: 2 }}>
                  Creato: {new Date(course.createdAt).toLocaleDateString()}
                </Typography>
              </CardContent>
              <CardActions>
                <IconButton onClick={() => handleOpenDialog(course)} color="primary">
                  <EditIcon />
                </IconButton>
                <IconButton onClick={() => handleDelete(course.courseId)} color="error">
                  <DeleteIcon />
                </IconButton>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Dialog for Create/Edit */}
      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          {editingCourse ? 'Modifica Corso' : 'Nuovo Corso'}
        </DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="Nome del corso"
            fullWidth
            variant="outlined"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            sx={{ mb: 2 }}
          />
          <TextField
            margin="dense"
            label="Descrizione"
            fullWidth
            multiline
            rows={4}
            variant="outlined"
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Annulla</Button>
          <Button onClick={handleSubmit} variant="contained">
            {editingCourse ? 'Salva' : 'Crea'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default CourseManager;