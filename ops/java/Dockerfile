# syntax=docker/dockerfile:1
FROM eclipse-temurin:21-jre-jammy
ARG JAR_FILE=target/app.jar
WORKDIR /app
COPY --chown=10001:10001 ${JAR_FILE} /app/app.jar
USER 10001:10001
EXPOSE 8080
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
