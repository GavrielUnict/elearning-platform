import React, { useState } from 'react';
import {
  Container,
  Paper,
  TextField,
  Button,
  Typography,
  Box,
  Alert,
  Link,
  Stepper,
  Step,
  StepLabel,
} from '@mui/material';
import { useNavigate, Link as RouterLink } from 'react-router-dom';
import { authService } from '../../services/auth';

const ForgotPassword = () => {
  const navigate = useNavigate();
  const [activeStep, setActiveStep] = useState(0);
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const steps = ['Inserisci email', 'Inserisci codice', 'Nuova password'];

  const handleEmailSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await authService.forgotPassword(email);
      setActiveStep(1);
    } catch (error) {
      setError(error.message || 'Errore durante l\'invio del codice');
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async (e) => {
    e.preventDefault();
    setError('');

    if (newPassword !== confirmPassword) {
      setError('Le password non corrispondono');
      return;
    }

    setLoading(true);

    try {
      await authService.forgotPasswordSubmit(email, code, newPassword);
      setActiveStep(2);
      setTimeout(() => {
        navigate('/login');
      }, 2000);
    } catch (error) {
      setError(error.message || 'Errore durante il reset della password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container component="main" maxWidth="xs">
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <Paper elevation={3} sx={{ padding: 4, width: '100%' }}>
          <Typography component="h1" variant="h5" align="center">
            Recupera Password
          </Typography>

          <Stepper activeStep={activeStep} sx={{ mt: 3, mb: 3 }}>
            {steps.map((label) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          {activeStep === 0 && (
            <Box component="form" onSubmit={handleEmailSubmit}>
              <TextField
                margin="normal"
                required
                fullWidth
                label="Email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoFocus
              />
              
              <Button
                type="submit"
                fullWidth
                variant="contained"
                sx={{ mt: 3, mb: 2 }}
                disabled={loading}
              >
                {loading ? 'Invio in corso...' : 'Invia codice'}
              </Button>
            </Box>
          )}

          {activeStep === 1 && (
            <Box component="form" onSubmit={handleResetPassword}>
              <TextField
                margin="normal"
                required
                fullWidth
                label="Codice di verifica"
                value={code}
                onChange={(e) => setCode(e.target.value)}
                autoFocus
              />
              
              <TextField
                margin="normal"
                required
                fullWidth
                label="Nuova password"
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
              />
              
              <TextField
                margin="normal"
                required
                fullWidth
                label="Conferma password"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
              />
              
              <Button
                type="submit"
                fullWidth
                variant="contained"
                sx={{ mt: 3, mb: 2 }}
                disabled={loading}
              >
                {loading ? 'Reset in corso...' : 'Reimposta password'}
              </Button>
            </Box>
          )}

          {activeStep === 2 && (
            <Alert severity="success">
              Password reimpostata con successo! Reindirizzamento al login...
            </Alert>
          )}

          <Box sx={{ textAlign: 'center', mt: 2 }}>
            <Link component={RouterLink} to="/login" variant="body2">
              Torna al login
            </Link>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
};

export default ForgotPassword;