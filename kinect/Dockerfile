FROM eclipse-temurin:21-jdk-jammy AS build
LABEL authors="ouznoreyni"

WORKDIR /app

# Copy Maven wrapper and other necessary files with correct permissions
COPY --chmod=0755 .mvn .mvn
COPY --chmod=0755 mvnw .
COPY pom.xml .
COPY ./src src/

# Download project dependencies
RUN ./mvnw dependency:go-offline -B -DskipTests

FROM build AS test
COPY src src
# Set the Spring profile to test
RUN ./mvnw test -Dspring.profiles.active=test
CMD ["./mvnw", "test", "-Dspring.profiles.active=test"]

FROM build AS dev
ARG SPRING_PROFILE=dev
ENV SPRING_PROFILE=${SPRING_PROFILE}
COPY src src
RUN --mount=type=cache,target=/root/.m2 ./mvnw package -DskipTests

RUN adduser --disabled-password --gecos "" --shell "/bin/false" appuser
USER appuser
CMD ["java", "-Dspring.profiles.active=${SPRING_PROFILE}", "-jar", "/app/target/*.jar"]

FROM eclipse-temurin:21-jre-jammy AS prod
ARG SPRING_PROFILE=prod
ENV SPRING_PROFILE=${SPRING_PROFILE}
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080

RUN adduser --disabled-password --gecos "" --shell "/bin/false" appuser
USER appuser
ENTRYPOINT ["java", "-Dspring.profiles.active=${SPRING_PROFILE}", "-jar", "app.jar"]