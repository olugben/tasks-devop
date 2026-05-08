package com.hammed.devops.task.api.dto;



public record TaskResponse(
        Long id,
        String title,
        String description,
        String status
) {
}