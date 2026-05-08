package com.hammed.devops.task.api.repository;
import com.hammed.devops.task.api.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TaskRepository extends JpaRepository<Task, Long> {
}




