package com.hammed.devops.task.api.service;

import com.hammed.devops.task.api.dto.CreateTaskRequest;
import com.hammed.devops.task.api.dto.TaskResponse;
import com.hammed.devops.task.api.dto.UpdateTaskStatusRequest;
import com.hammed.devops.task.api.entity.Task;
import com.hammed.devops.task.api.exception.ResourceNotFoundException;
import com.hammed.devops.task.api.mapper.TaskMapper;
import com.hammed.devops.task.api.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;

    public TaskResponse createTask(CreateTaskRequest request) {

        Task task = Task.builder()
                .title(request.title())
                .description(request.description())
                .status("PENDING")
                .build();

        return TaskMapper.toResponse(taskRepository.save(task));
    }

    public List<TaskResponse> getTasks() {

        return taskRepository.findAll()
                .stream()
                .map(TaskMapper::toResponse)
                .toList();
    }

    public TaskResponse updateStatus(
            Long id,
            UpdateTaskStatusRequest request
    ) {

        Task task = taskRepository.findById(id)
                .orElseThrow(() ->
                        new ResourceNotFoundException("Task not found")
                );

        task.setStatus(request.status());

        return TaskMapper.toResponse(taskRepository.save(task));
    }
}