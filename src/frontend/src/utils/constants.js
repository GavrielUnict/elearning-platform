export const ROLES = {
  TEACHER: 'Docenti',
  STUDENT: 'Studenti',
};

export const ENROLLMENT_STATUS = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
};

export const DOCUMENT_STATUS = {
  PENDING: 'pending',
  READY: 'ready',
  FAILED: 'failed',
};

export const QUIZ_PASSING_SCORE = 60;

export const API_ENDPOINTS = {
  COURSES: '/courses',
  ENROLLMENTS: '/enrollments',
  DOCUMENTS: '/documents',
  QUIZ: '/quiz',
  RESULTS: '/results',
};

export const ERROR_MESSAGES = {
  GENERIC: 'Si è verificato un errore. Riprova più tardi.',
  UNAUTHORIZED: 'Non sei autorizzato a eseguire questa operazione.',
  NOT_FOUND: 'Risorsa non trovata.',
  NETWORK: 'Errore di connessione. Verifica la tua connessione internet.',
};

export const SUCCESS_MESSAGES = {
  COURSE_CREATED: 'Corso creato con successo!',
  COURSE_UPDATED: 'Corso aggiornato con successo!',
  COURSE_DELETED: 'Corso eliminato con successo!',
  ENROLLMENT_REQUESTED: 'Richiesta di iscrizione inviata!',
  ENROLLMENT_APPROVED: 'Iscrizione approvata!',
  ENROLLMENT_REJECTED: 'Iscrizione rifiutata!',
  DOCUMENT_UPLOADED: 'Documento caricato con successo!',
  DOCUMENT_DELETED: 'Documento eliminato con successo!',
  QUIZ_SUBMITTED: 'Quiz completato con successo!',
};