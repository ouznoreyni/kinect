# Building and Running the Dockerfile

This Dockerfile is designed to build and run a Spring Boot application in different environments such as development, testing, and production. It uses Docker multi-stage builds to optimize the Docker image size and improve caching efficiency.


## Docker for Spring Boot Application

This guide walks you through the process of building and running Docker images for a Spring Boot application with different profiles (test, dev, prod).

## Prerequisites

- Docker installed on your machine
- Java 21 or higher

## Step 1: Build the Docker Images

Navigate to the project directory containing the Dockerfile.

### Build Test Image

```
docker build --progress=plain --no-cache --target test -t kinect-test .
```

### Build Development Image

```
docker build --target dev -t kinect-dev .
```

### Build Production Image

```
docker build --target prod -t kinect-prod .
```

## Step 2: Run the Docker Containers

### Run Tests

```
docker run kinect-test
```

This command will run the tests inside the Docker container.

### Run in Development Mode

```
docker run kinect-dev
```

This command will run the application in development mode inside the Docker container.

### Run in Production Mode

```
docker run -p 8080:8080 kinect-prod
```

This command will run the application in production mode inside the Docker container and map the container's port 8080 to the host's port 8080.

## Step 3 (Optional): Customize Spring Profiles

You can customize the Spring profile used for the `dev` and `prod` stages by providing the `SPRING_PROFILE` build argument:

```
docker build --build-arg SPRING_PROFILE=custom-profile --target dev -t kinect-dev .
docker build --build-arg SPRING_PROFILE=custom-profile --target prod -t ykinect-prod .
```

Replace `custom-profile` with the desired Spring profile name.

## Notes

- The Dockerfile creates a non-root user (`appuser`) to run the application in the `dev` and `prod` stages for better security.
- The `test` stage runs the tests using the `CMD` instruction, while the `dev` and `prod` stages run the application using the `CMD` or `ENTRYPOINT` instructions.
- The `prod` stage exposes port 8080 for the application to listen on.

This Markdown file includes all the necessary steps to build the Docker images for the test, development, and production stages, as well as instructions on how to run the containers for each stage. It also includes an optional step to customize the Spring profile used for the `dev` and `prod` stages, and some additional notes about the Dockerfile.