package com.hammed.devops.task.api.controller;



import com.hammed.devops.task.api.dto.CreateTaskRequest;
import com.hammed.devops.task.api.dto.TaskResponse;
import com.hammed.devops.task.api.dto.UpdateTaskStatusRequest;
import com.hammed.devops.task.api.service.TaskService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    @PostMapping
    public TaskResponse createTask(
            @Valid @RequestBody CreateTaskRequest request
    ) {

        return taskService.createTask(request);
    }

    @GetMapping
    public List<TaskResponse> getTasks() {
        return taskService.getTasks();
    }

    @PatchMapping("/{id}/status")
    public TaskResponse updateStatus(
            @PathVariable Long id,
            @Valid @RequestBody UpdateTaskStatusRequest request
    ) {

        return taskService.updateStatus(id, request);
    }
}