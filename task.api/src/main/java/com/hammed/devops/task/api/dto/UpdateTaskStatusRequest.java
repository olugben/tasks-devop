package com.hammed.devops.task.api.dto;


import jakarta.validation.constraints.NotBlank;

public record UpdateTaskStatusRequest(

        @NotBlank
        String status
) {
}
