package com.hammed.devops.task.api.controller;



import com.fasterxml.jackson.databind.ObjectMapper;
import com.hammed.devops.task.api.dto.CreateTaskRequest;
import com.hammed.devops.task.api.dto.TaskResponse;
import com.hammed.devops.task.api.service.TaskService;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(TaskController.class)
class TaskControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TaskService taskService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldCreateTask() throws Exception {

        // FIXED: record-style request (NO setters)
        CreateTaskRequest request = new CreateTaskRequest(
                "Test Task",
                "Test Description"
        );

        // FIXED: record-style response (NO setters)
        TaskResponse response = new TaskResponse(
                1L,
                "Test Task",
                "Test Description",
                "PENDING"
        );

        Mockito.when(taskService.createTask(Mockito.any()))
                .thenReturn(response);

        mockMvc.perform(post("/api/tasks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.title").value("Test Task"))
                .andExpect(jsonPath("$.description").value("Test Description"))
                .andExpect(jsonPath("$.status").value("PENDING"));
    }
}