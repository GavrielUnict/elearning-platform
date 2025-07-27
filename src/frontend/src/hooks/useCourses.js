import { useQuery, useMutation, useQueryClient } from 'react-query';
import { courseAPI } from '../services/api';

export const useCourses = () => {
  return useQuery('courses', courseAPI.list, {
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
};

export const useCourse = (courseId) => {
  return useQuery(['course', courseId], () => courseAPI.get(courseId), {
    enabled: !!courseId,
  });
};

export const useCreateCourse = () => {
  const queryClient = useQueryClient();
  
  return useMutation(courseAPI.create, {
    onSuccess: () => {
      queryClient.invalidateQueries('courses');
    },
  });
};

export const useUpdateCourse = () => {
  const queryClient = useQueryClient();
  
  return useMutation(
    ({ courseId, data }) => courseAPI.update(courseId, data),
    {
      onSuccess: (_, { courseId }) => {
        queryClient.invalidateQueries(['course', courseId]);
        queryClient.invalidateQueries('courses');
      },
    }
  );
};

export const useDeleteCourse = () => {
  const queryClient = useQueryClient();
  
  return useMutation(courseAPI.delete, {
    onSuccess: () => {
      queryClient.invalidateQueries('courses');
    },
  });
};