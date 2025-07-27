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
  Quiz as QuizIcon,
  History as HistoryIcon,
} from '@mui/icons-material';
import Header from '../common/Header';
import CourseList from './CourseList';
import CourseView from './CourseView';
import QuizRunner from './QuizRunner';
import ResultsHistory from './ResultsHistory';

const drawerWidth = 240;

const StudentDashboard = () => {
  const navigate = useNavigate();

  const menuItems = [
    { text: 'Corsi disponibili', icon: <SchoolIcon />, path: '/student' },
    { text: 'I miei corsi', icon: <AssignmentIcon />, path: '/student/my-courses' },
    { text: 'Quiz', icon: <QuizIcon />, path: '/student/quizzes' },
    { text: 'Risultati', icon: <HistoryIcon />, path: '/student/results' },
  ];

  return (
    <Box sx={{ display: 'flex' }}>
      <Header title="Dashboard Studente" />
      
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
          <Route path="/" element={<CourseList showAll={true} />} />
          <Route path="/my-courses" element={<CourseList showAll={false} />} />
          <Route path="/course/:courseId" element={<CourseView />} />
          <Route path="/quiz/:courseId/:documentId" element={<QuizRunner />} />
          <Route path="/quizzes" element={<CourseList showAll={false} quizMode={true} />} />
          <Route path="/results" element={<ResultsHistory />} />
        </Routes>
      </Box>
    </Box>
  );
};

export default StudentDashboard;