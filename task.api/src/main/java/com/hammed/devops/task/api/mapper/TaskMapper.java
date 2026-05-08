package com.hammed.devops.task.api.mapper;


import com.hammed.devops.task.api.dto.TaskResponse;
import com.hammed.devops.task.api.entity.Task;

public class TaskMapper {

    private TaskMapper() {
    }

    public static TaskResponse toResponse(Task task) {
        return new TaskResponse(
                task.getId(),
                task.getTitle(),
                task.getDescription(),
                task.getStatus()
        );
    }
}