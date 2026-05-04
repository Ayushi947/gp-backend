# ============================================
# Multi-stage Dockerfile for GlidingPath Backend
# Optimized for production performance
# ============================================

# ---------- Build Stage ----------
FROM gradle:8.13-jdk21-alpine AS build

# Set build arguments for better caching
ARG GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Dorg.gradle.caching=true"

# Use /app as working directory
WORKDIR /app

# Copy Gradle wrapper and build files first (better layer caching)
COPY gradle gradle
COPY gradlew .
COPY build.gradle settings.gradle ./

# Copy module build files (improves caching for dependencies)
COPY modules/*/build.gradle modules/

# Download dependencies (cached layer if dependencies don't change)
RUN ./gradlew dependencies --no-daemon || true

# Copy source code
COPY src src
COPY modules modules

# Build the application
# - Skip tests for faster Docker builds (run tests in CI/CD)
# - Use bootJar to create fat JAR
# - No daemon for Docker builds
RUN ./gradlew clean bootJar -x test --no-daemon --build-cache \
    && echo "Build completed successfully"

# ---------- Runtime Stage ----------
FROM eclipse-temurin:21-jre-alpine AS runtime

# Install curl for health checks
RUN apk add --no-cache curl

# Create non-root user for security
RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    mkdir -p /app /app/logs && \
    chown -R appuser:appgroup /app

# Set working directory
WORKDIR /app

# Copy JAR from build stage
COPY --from=build --chown=appuser:appgroup /app/build/libs/*.jar app.jar

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 9090

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:9090/v1/api/actuator/health || exit 1

# JVM performance tuning for containers
ENV JAVA_OPTS="\
    -Xms512m \
    -Xmx2g \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:+HeapDumpOnOutOfMemoryError \
    -XX:HeapDumpPath=/app/logs \
    -Djava.security.egd=file:/dev/./urandom \
    -Dspring.profiles.active=dev"

    

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
