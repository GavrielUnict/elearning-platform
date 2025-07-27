import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Grid,
  Alert,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  LinearProgress,
  Chip,
  Divider,
} from '@mui/material';
import {
  CloudUpload as UploadIcon,
  Delete as DeleteIcon,
  Download as DownloadIcon,
  PictureAsPdf as PdfIcon,
  Quiz as QuizIcon,
} from '@mui/icons-material';
import { documentAPI } from '../../services/api';
import { useCourses } from '../../hooks/useCourses';
import LoadingSpinner from '../common/LoadingSpinner';

const DocumentUpload = () => {
  const { data: coursesData, isLoading } = useCourses();
  const [selectedCourse, setSelectedCourse] = useState(null);
  const [documents, setDocuments] = useState([]);
  const [loadingDocuments, setLoadingDocuments] = useState(false);
  const [uploadDialog, setUploadDialog] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const courses = coursesData?.data?.courses || [];

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    if (selectedCourse) {
      fetchDocuments();
    }
  }, [selectedCourse]);

  const fetchDocuments = async () => {
    setLoadingDocuments(true);
    setError('');
    try {
      const response = await documentAPI.list(selectedCourse);
      setDocuments(response.data.documents);
    } catch (error) {
      setError('Errore nel caricamento dei documenti');
      console.error('Error fetching documents:', error);
    } finally {
      setLoadingDocuments(false);
    }
  };

  const handleFileSelect = async (event) => {
    const file = event.target.files[0];
    if (!file) return;

    if (!file.name.toLowerCase().endsWith('.pdf')) {
      setError('Solo file PDF sono permessi');
      return;
    }

    setError('');
    setSuccess('');
    setUploading(true);
    setUploadProgress(0);

    try {
      // Get presigned URL
      const response = await documentAPI.getUploadUrl(
        selectedCourse,
        file.name,
        file.size
      );

      const { uploadUrl } = response.data;

      // Upload file to S3
      const xhr = new XMLHttpRequest();

      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable) {
          const percentComplete = (e.loaded / e.total) * 100;
          setUploadProgress(percentComplete);
        }
      });

      xhr.addEventListener('load', async () => {
        if (xhr.status === 200) {
          setSuccess('Documento caricato con successo!');
          setUploadDialog(false);
          await fetchDocuments();
        } else {
          setError('Errore durante il caricamento');
        }
        setUploading(false);
      });

      xhr.addEventListener('error', () => {
        setError('Errore durante il caricamento');
        setUploading(false);
      });

      xhr.open('PUT', uploadUrl);
      xhr.setRequestHeader('Content-Type', 'application/pdf');
      xhr.send(file);

    } catch (error) {
      setError('Errore durante la richiesta di upload');
      setUploading(false);
      console.error('Error uploading:', error);
    }
  };

  const handleDownload = async (document) => {
    try {
      const response = await documentAPI.getDownloadUrl(selectedCourse, document.documentId);
      window.open(response.data.downloadUrl, '_blank');
    } catch (error) {
      setError('Errore durante il download');
      console.error('Error downloading:', error);
    }
  };

  const handleDelete = async (documentId) => {
    if (!window.confirm('Sei sicuro di voler eliminare questo documento?')) {
      return;
    }

    try {
      await documentAPI.delete(selectedCourse, documentId);
      setSuccess('Documento eliminato con successo');
      await fetchDocuments();
    } catch (error) {
      setError('Errore durante l\'eliminazione');
      console.error('Error deleting:', error);
    }
  };

  if (isLoading) return <LoadingSpinner />;

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Gestione Documenti
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

      {/* Documents */}
      {selectedCourse && (
        <Card>
          <CardContent>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
              <Typography variant="h6">Documenti del corso</Typography>
              <Button
                variant="contained"
                startIcon={<UploadIcon />}
                onClick={() => setUploadDialog(true)}
              >
                Carica PDF
              </Button>
            </Box>

            <Divider sx={{ mb: 2 }} />

            {loadingDocuments ? (
              <LoadingSpinner />
            ) : documents.length === 0 ? (
              <Typography variant="body2" color="text.secondary" textAlign="center">
                Nessun documento caricato
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
                            <Typography variant="caption" display="block">
                              Caricato: {new Date(doc.uploadedAt).toLocaleString()}
                            </Typography>
                            <Box sx={{ mt: 1 }}>
                              <Chip
                                label={doc.status}
                                size="small"
                                color={doc.status === 'ready' ? 'success' : 'warning'}
                                sx={{ mr: 1 }}
                              />
                              {doc.quizId && (
                                <Chip
                                  icon={<QuizIcon />}
                                  label="Quiz disponibile"
                                  size="small"
                                  color="primary"
                                />
                              )}
                            </Box>
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
                        <IconButton
                          edge="end"
                          color="error"
                          onClick={() => handleDelete(doc.documentId)}
                        >
                          <DeleteIcon />
                        </IconButton>
                      </ListItemSecondaryAction>
                    </ListItem>
                    <Divider />
                  </React.Fragment>
                ))}
              </List>
            )}
          </CardContent>
        </Card>
      )}

      {/* Upload Dialog */}
      <Dialog open={uploadDialog} onClose={() => !uploading && setUploadDialog(false)}>
        <DialogTitle>Carica Documento PDF</DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <input
              accept="application/pdf"
              style={{ display: 'none' }}
              id="pdf-file-input"
              type="file"
              onChange={handleFileSelect}
              disabled={uploading}
            />
            <label htmlFor="pdf-file-input">
              <Button
                variant="outlined"
                component="span"
                startIcon={<UploadIcon />}
                disabled={uploading}
                fullWidth
              >
                Seleziona file PDF
              </Button>
            </label>

            {uploading && (
              <Box sx={{ mt: 2 }}>
                <Typography variant="body2" gutterBottom>
                  Caricamento in corso...
                </Typography>
                <LinearProgress variant="determinate" value={uploadProgress} />
                <Typography variant="caption" color="text.secondary">
                  {Math.round(uploadProgress)}%
                </Typography>
              </Box>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setUploadDialog(false)} disabled={uploading}>
            Chiudi
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DocumentUpload;