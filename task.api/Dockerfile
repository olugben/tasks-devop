# Stage 1: Build the application
FROM maven:3.9.6-eclipse-temurin-21 AS build

# Set working directory
WORKDIR /app

# Copy all files from current build context
COPY . .

# Download dependencies
RUN mvn dependency:go-offline

# Build jar
RUN mvn clean package -DskipTests


# Stage 2: Run the application
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Create non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy jar from build stage
COPY --from=build /app/target/*.jar app.jar

# Change ownership
RUN chown appuser:appgroup app.jar

# Switch user
USER appuser

# Expose app port
EXPOSE 8080

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]