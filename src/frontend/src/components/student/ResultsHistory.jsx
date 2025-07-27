import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip,
  Grid,
  Alert,
  LinearProgress,
  List,
  ListItem,
  ListItemText,
  Divider,
} from '@mui/material';
import {
  ExpandMore as ExpandMoreIcon,
  CheckCircle as CorrectIcon,
  Cancel as WrongIcon,
  Description as DocumentIcon,
} from '@mui/icons-material';
import { resultsAPI } from '../../services/api';
import LoadingSpinner from '../common/LoadingSpinner';

const ResultsHistory = () => {
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [expanded, setExpanded] = useState(false);

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    fetchResults();
  }, []);

  const fetchResults = async () => {
    setLoading(true);
    setError('');
    
    try {
      const response = await resultsAPI.list();
      setResults(response.data.results);
    } catch (error) {
      setError('Errore nel caricamento dei risultati');
      console.error('Error fetching results:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAccordionChange = (panel) => (event, isExpanded) => {
    setExpanded(isExpanded ? panel : false);
  };

  if (loading) return <LoadingSpinner />;

  const summary = results.length > 0 ? {
    totalQuizzes: results.length,
    averageScore: Math.round(
      results.reduce((sum, r) => sum + r.averageScore, 0) / results.length
    ),
    totalAttempts: results.reduce((sum, r) => sum + r.totalAttempts, 0),
  } : null;

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        I Miei Risultati
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Summary Card */}
      {summary && (
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Riepilogo
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={4}>
                <Typography variant="h3" color="primary">
                  {summary.totalQuizzes}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Quiz Completati
                </Typography>
              </Grid>
              <Grid item xs={12} sm={4}>
                <Typography variant="h3" color="primary">
                  {summary.averageScore}%
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Media Voti
                </Typography>
              </Grid>
              <Grid item xs={12} sm={4}>
                <Typography variant="h3" color="primary">
                  {summary.totalAttempts}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Tentativi Totali
                </Typography>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      )}

      {/* Results List */}
      {results.length === 0 ? (
        <Card>
          <CardContent>
            <Typography variant="body2" color="text.secondary" textAlign="center">
              Non hai ancora completato nessun quiz
            </Typography>
          </CardContent>
        </Card>
      ) : (
        results.map((quizResult, index) => (
          <Accordion
            key={quizResult.quizId}
            expanded={expanded === `panel${index}`}
            onChange={handleAccordionChange(`panel${index}`)}
            sx={{ mb: 1 }}
          >
            <AccordionSummary expandIcon={<ExpandMoreIcon />}>
              <Box sx={{ display: 'flex', alignItems: 'center', width: '100%' }}>
                <DocumentIcon sx={{ mr: 2 }} />
                <Box sx={{ flexGrow: 1 }}>
                  <Typography variant="h6">
                    Quiz #{index + 1}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Miglior voto: {quizResult.bestScore}% | 
                    Tentativi: {quizResult.totalAttempts}
                  </Typography>
                </Box>
                <Chip
                  label={`${quizResult.bestScore}%`}
                  color={quizResult.bestScore >= 60 ? 'success' : 'error'}
                  sx={{ mr: 2 }}
                />
              </Box>
            </AccordionSummary>
            
            <AccordionDetails>
              {/* Last Attempt Details */}
              <Typography variant="subtitle1" gutterBottom>
                Ultimo Tentativo
              </Typography>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Data: {new Date(quizResult.lastAttempt.completedAt).toLocaleString()}
              </Typography>
              <Typography variant="body2" gutterBottom>
                Risultato: {quizResult.lastAttempt.correctAnswers} su {quizResult.lastAttempt.totalQuestions} 
                ({quizResult.lastAttempt.score}%)
              </Typography>
              
              <Divider sx={{ my: 2 }} />
              
              {/* Questions Review */}
              <Typography variant="subtitle1" gutterBottom>
                Revisione Domande
              </Typography>
              <List>
                {quizResult.lastAttempt.detailedResults.map((question, qIndex) => (
                  <React.Fragment key={question.questionId}>
                    <ListItem alignItems="flex-start">
                      <ListItemText
                        primary={
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            {question.isCorrect ? (
                              <CorrectIcon color="success" sx={{ mr: 1 }} />
                            ) : (
                              <WrongIcon color="error" sx={{ mr: 1 }} />
                            )}
                            <Typography variant="body1">
                              Domanda {qIndex + 1}: {question.question}
                            </Typography>
                          </Box>
                        }
                        secondary={
                          <Box sx={{ mt: 1 }}>
                            <Typography variant="body2">
                              La tua risposta: {question.studentAnswer !== null ? 
                                `Opzione ${question.studentAnswer + 1}` : 'Non risposto'}
                            </Typography>
                            <Typography variant="body2" color="success.main">
                              Risposta corretta: Opzione {question.correctAnswer + 1}
                            </Typography>
                          </Box>
                        }
                      />
                    </ListItem>
                    {qIndex < quizResult.lastAttempt.detailedResults.length - 1 && <Divider />}
                  </React.Fragment>
                ))}
              </List>
              
              {/* Progress Bar */}
              <Box sx={{ mt: 3 }}>
                <Typography variant="body2" gutterBottom>
                  Progresso Complessivo
                </Typography>
                <LinearProgress 
                  variant="determinate" 
                  value={quizResult.lastAttempt.score} 
                  color={quizResult.lastAttempt.score >= 60 ? 'success' : 'error'}
                  sx={{ height: 10, borderRadius: 5 }}
                />
              </Box>
            </AccordionDetails>
          </Accordion>
        ))
      )}
    </Box>
  );
};

export default ResultsHistory;