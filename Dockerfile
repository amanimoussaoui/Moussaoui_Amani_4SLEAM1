FROM eclipse-temurin:17-jdk-alpine

LABEL authors="redfox"

WORKDIR /app

COPY target/student-management-0.0.1-SNAPSHOT.jar student-management.jar

EXPOSE 8089

ENTRYPOINT ["java", "-jar", "/app/student-management.jar"]

