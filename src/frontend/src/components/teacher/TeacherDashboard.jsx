import React from 'react';
import { Routes, Route, useNavigate } from 'react-router-dom';
import {
  Box,
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  ListItemButton,
  Toolbar,
} from '@mui/material';
import {
  School as SchoolIcon,
  Assignment as AssignmentIcon,
  People as PeopleIcon,
} from '@mui/icons-material';
import Header from '../common/Header';
import CourseManager from './CourseManager';
import EnrollmentApproval from './EnrollmentApproval';
import DocumentUpload from './DocumentUpload';

const drawerWidth = 240;

const TeacherDashboard = () => {
  const navigate = useNavigate();

  const menuItems = [
    { text: 'I miei corsi', icon: <SchoolIcon />, path: '/teacher' },
    { text: 'Gestione iscrizioni', icon: <PeopleIcon />, path: '/teacher/enrollments' },
    { text: 'Documenti', icon: <AssignmentIcon />, path: '/teacher/documents' },
  ];

  return (
    <Box sx={{ display: 'flex' }}>
      <Header title="Dashboard Docente" />
      
      <Drawer
        variant="permanent"
        sx={{
          width: drawerWidth,
          flexShrink: 0,
          '& .MuiDrawer-paper': {
            width: drawerWidth,
            boxSizing: 'border-box',
          },
        }}
      >
        <Toolbar />
        <Box sx={{ overflow: 'auto' }}>
          <List>
            {menuItems.map((item) => (
              <ListItem key={item.text} disablePadding>
                <ListItemButton onClick={() => navigate(item.path)}>
                  <ListItemIcon>{item.icon}</ListItemIcon>
                  <ListItemText primary={item.text} />
                </ListItemButton>
              </ListItem>
            ))}
          </List>
        </Box>
      </Drawer>
      
      <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
        <Toolbar />
        <Routes>
          <Route path="/" element={<CourseManager />} />
          <Route path="/enrollments" element={<EnrollmentApproval />} />
          <Route path="/documents" element={<DocumentUpload />} />
        </Routes>
      </Box>
    </Box>
  );
};

export default TeacherDashboard;