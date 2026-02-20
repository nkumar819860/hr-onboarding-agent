# Multi-stage build for Mule application
FROM maven:3.9-eclipse-temurin-17 AS builder

# Set working directory
WORKDIR /app

# Copy pom.xml first for better layer caching
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests=true -B

# Runtime stage
FROM mulesoft/mule:4.5.0-java17

# Set environment variables
ENV MULE_HOME=/opt/mule
ENV MULE_APPS=$MULE_HOME/apps
ENV JAVA_OPTS="-Xmx1024m -XX:+UseG1GC"

# Create app user
RUN groupadd -r mule && useradd -r -g mule mule

# Copy the built JAR from builder stage
COPY --from=builder /app/target/*.jar $MULE_APPS/

# Copy configuration files
COPY --from=builder /app/src/main/resources/config.properties $MULE_HOME/conf/
COPY --from=builder /app/src/main/resources/asset-init.sql $MULE_HOME/conf/

# Create data directory for H2 database
RUN mkdir -p /opt/mule/data && chown -R mule:mule /opt/mule

# Switch to mule user
USER mule

# Expose port
EXPOSE 8082

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8082/mcp/health || exit 1

# Start Mule runtime
CMD ["$MULE_HOME/bin/mule", "start", "-M-Dmule.verbose.exceptions=true"]
