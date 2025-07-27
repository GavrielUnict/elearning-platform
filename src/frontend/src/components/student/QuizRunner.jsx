import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Radio,
  RadioGroup,
  FormControlLabel,
  FormControl,
  Alert,
  LinearProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Chip,
} from '@mui/material';
import {
  CheckCircle as CorrectIcon,
  Cancel as WrongIcon,
} from '@mui/icons-material';
import { useParams, useNavigate } from 'react-router-dom';
import { quizAPI } from '../../services/api';
import LoadingSpinner from '../common/LoadingSpinner';

const QuizRunner = () => {
  const { courseId, documentId } = useParams();
  const navigate = useNavigate();
  
  const [quiz, setQuiz] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState({});
  const [submitted, setSubmitted] = useState(false);
  const [results, setResults] = useState(null);
  const [showResults, setShowResults] = useState(false);

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    fetchQuiz();
  }, [courseId, documentId]);

  const fetchQuiz = async () => {
    setLoading(true);
    setError('');
    
    try {
      const response = await quizAPI.get(courseId, documentId);
      setQuiz(response.data.quiz);
      
      // Initialize answers object
      const initialAnswers = {};
      response.data.quiz.questions.forEach(q => {
        initialAnswers[q.questionId] = null;
      });
      setAnswers(initialAnswers);
    } catch (error) {
      setError('Errore nel caricamento del quiz');
      console.error('Error fetching quiz:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAnswerChange = (questionId, value) => {
    setAnswers({
      ...answers,
      [questionId]: parseInt(value)
    });
  };

  const handleNext = () => {
    if (currentQuestion < quiz.questions.length - 1) {
      setCurrentQuestion(currentQuestion + 1);
    }
  };

  const handlePrevious = () => {
    if (currentQuestion > 0) {
      setCurrentQuestion(currentQuestion - 1);
    }
  };

  const handleSubmit = async () => {
    // Check if all questions are answered
    const unanswered = Object.values(answers).filter(a => a === null).length;
    if (unanswered > 0) {
      setError(`Ci sono ancora ${unanswered} domande senza risposta`);
      return;
    }

    setSubmitted(true);
    setError('');
    
    try {
      const response = await quizAPI.submit(courseId, documentId, {
        quizId: quiz.quizId,
        answers: answers
      });
      
      setResults(response.data.result);
      setShowResults(true);
    } catch (error) {
      setError('Errore durante l\'invio del quiz');
      console.error('Error submitting quiz:', error);
      setSubmitted(false);
    }
  };

  if (loading) return <LoadingSpinner />;
  if (!quiz) return <Alert severity="error">Quiz non trovato</Alert>;

  const question = quiz.questions[currentQuestion];
  const progress = ((currentQuestion + 1) / quiz.questions.length) * 100;

  return (
    <Box>
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h4" gutterBottom>
            Quiz: {quiz.documentName}
          </Typography>
          
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <Box sx={{ width: '100%', mr: 1 }}>
              <LinearProgress variant="determinate" value={progress} />
            </Box>
            <Box sx={{ minWidth: 100 }}>
              <Typography variant="body2" color="text.secondary">
                Domanda {currentQuestion + 1} di {quiz.questions.length}
              </Typography>
            </Box>
          </Box>
        </CardContent>
      </Card>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Question Card */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            {question.question}
          </Typography>
          
          <FormControl component="fieldset" sx={{ mt: 2, width: '100%' }}>
            <RadioGroup
              value={answers[question.questionId] !== null ? answers[question.questionId].toString() : ''}
              onChange={(e) => handleAnswerChange(question.questionId, e.target.value)}
            >
              {question.options.map((option, index) => (
                <FormControlLabel
                  key={index}
                  value={index.toString()}
                  control={<Radio />}
                  label={option}
                  disabled={submitted}
                  sx={{ mb: 1 }}
                />
              ))}
            </RadioGroup>
          </FormControl>
          
          {/* Navigation Buttons */}
          <Box sx={{ mt: 4, display: 'flex', justifyContent: 'space-between' }}>
            <Button
              onClick={handlePrevious}
              disabled={currentQuestion === 0 || submitted}
            >
              Precedente
            </Button>
            
            <Box>
              {currentQuestion < quiz.questions.length - 1 ? (
                <Button
                  variant="contained"
                  onClick={handleNext}
                  disabled={answers[question.questionId] === null || submitted}
                >
                  Successiva
                </Button>
              ) : (
                <Button
                  variant="contained"
                  color="success"
                  onClick={handleSubmit}
                  disabled={submitted}
                >
                  {submitted ? 'Invio in corso...' : 'Invia Quiz'}
                </Button>
              )}
            </Box>
          </Box>
        </CardContent>
      </Card>

      {/* Results Dialog */}
      <Dialog 
        open={showResults} 
        onClose={() => navigate(`/student/results`)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          Risultati Quiz
        </DialogTitle>
        <DialogContent>
          <Box textAlign="center" py={2}>
            <Typography variant="h2" color="primary" gutterBottom>
              {results?.score}%
            </Typography>
            
            <Typography variant="h6" gutterBottom>
              Risposte corrette: {results?.correctAnswers} su {results?.totalQuestions}
            </Typography>
            
            {results?.score >= 60 ? (
              <Chip
                icon={<CorrectIcon />}
                label="Quiz Superato!"
                color="success"
                sx={{ mt: 2 }}
              />
            ) : (
              <Chip
                icon={<WrongIcon />}
                label="Quiz Non Superato"
                color="error"
                sx={{ mt: 2 }}
              />
            )}
          </Box>
          
          <DialogContentText sx={{ mt: 2 }}>
            Il quiz è stato completato e salvato. Puoi rivedere le tue risposte 
            e quelle corrette nella sezione "Risultati".
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => navigate(`/student/course/${courseId}`)}>
            Torna al Corso
          </Button>
          <Button 
            variant="contained" 
            onClick={() => navigate(`/student/results`)}
          >
            Vedi Dettagli
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default QuizRunner;