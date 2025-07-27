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
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
} from '@mui/material';
import { useNavigate, Link as RouterLink } from 'react-router-dom';
import { authService } from '../../services/auth';

const Register = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    name: '',
    familyName: '',
    role: 'studente',
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [confirmDialog, setConfirmDialog] = useState(false);
  const [confirmCode, setConfirmCode] = useState('');

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (formData.password !== formData.confirmPassword) {
      setError('Le password non corrispondono');
      return;
    }

    setLoading(true);

    try {
      await authService.signUp(
        formData.email,
        formData.password,
        formData.name,
        formData.familyName,
        formData.role
      );
      setConfirmDialog(true);
    } catch (error) {
      setError(error.message || 'Errore durante la registrazione');
    } finally {
      setLoading(false);
    }
  };

  const handleConfirm = async () => {
    setError('');
    setLoading(true);

    try {
      await authService.confirmSignUp(formData.email, confirmCode);
      navigate('/login');
    } catch (error) {
      setError(error.message || 'Codice non valido');
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
            Registrazione
          </Typography>

          {error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {error}
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1 }}>
            <TextField
              margin="normal"
              required
              fullWidth
              name="name"
              label="Nome"
              autoFocus
              value={formData.name}
              onChange={handleChange}
            />
            
            <TextField
              margin="normal"
              required
              fullWidth
              name="familyName"
              label="Cognome"
              value={formData.familyName}
              onChange={handleChange}
            />
            
            <TextField
              margin="normal"
              required
              fullWidth
              name="email"
              label="Email"
              type="email"
              value={formData.email}
              onChange={handleChange}
            />
            
            <FormControl fullWidth margin="normal">
              <InputLabel>Ruolo</InputLabel>
              <Select
                name="role"
                value={formData.role}
                onChange={handleChange}
                label="Ruolo"
              >
                <MenuItem value="studente">Studente</MenuItem>
                <MenuItem value="docente">Docente</MenuItem>
              </Select>
            </FormControl>
            
            <TextField
              margin="normal"
              required
              fullWidth
              name="password"
              label="Password"
              type="password"
              value={formData.password}
              onChange={handleChange}
              helperText="Minimo 8 caratteri, con maiuscole, minuscole, numeri e simboli"
            />
            
            <TextField
              margin="normal"
              required
              fullWidth
              name="confirmPassword"
              label="Conferma Password"
              type="password"
              value={formData.confirmPassword}
              onChange={handleChange}
            />
            
            <Button
              type="submit"
              fullWidth
              variant="contained"
              sx={{ mt: 3, mb: 2 }}
              disabled={loading}
            >
              {loading ? 'Registrazione in corso...' : 'Registrati'}
            </Button>
            
            <Box sx={{ textAlign: 'center' }}>
              <Link component={RouterLink} to="/login" variant="body2">
                Hai già un account? Accedi
              </Link>
            </Box>
          </Box>
        </Paper>
      </Box>

      {/* Confirmation Dialog */}
      <Dialog open={confirmDialog} onClose={() => {}}>
        <DialogTitle>Conferma Email</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Abbiamo inviato un codice di conferma a {formData.email}.
            Inserisci il codice per completare la registrazione.
          </DialogContentText>
          <TextField
            autoFocus
            margin="dense"
            label="Codice di conferma"
            fullWidth
            variant="outlined"
            value={confirmCode}
            onChange={(e) => setConfirmCode(e.target.value)}
          />
          {error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {error}
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleConfirm} disabled={loading}>
            Conferma
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default Register;