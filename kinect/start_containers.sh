#!/bin/bash

# Define the PostgreSQL container name and Spring Boot application container name
ENV_FILE=.env.local

# Function to print colored and formatted messages
print_message() {
    local color=$1
    local icon=$2
    local message=$3

    case $color in
        green)
            color="\033[0;32m"
            ;;
        red)
            color="\033[0;31m"
            ;;
        yellow)
            color="\033[0;33m"
            ;;
        *)
            color=""
            ;;
    esac

    echo -e "${color}${icon} ${message}\033[0m"
}

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    print_message yellow "⏳" "Waiting for PostgreSQL to be ready..."
    while ! docker exec "$DB_CONTAINER_NAME" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h localhost -p 5432; do
        sleep 2
    done
    print_message green "✅" "PostgreSQL is ready!"
}

# Function to pull the PostgreSQL image if it doesn't exist
pull_postgres_image() {
    local postgres_image="$POSTGRES_IMAGE"
    docker pull "$postgres_image" || return 1
}

# Function to stop and remove existing containers and images based on the mode
stop_and_remove() {
    local mode="$MODE"
    local app_image="$APP_IMAGE:$mode"
    local db_container="$DB_CONTAINER_NAME"
    local app_container="$SPRING_BOOT_CONTAINER_NAME-$mode"

    print_message yellow "🛑" "Stopping and removing existing containers and images for mode: $mode..."

    # Stop and remove the app container
    docker stop "$app_container" >/dev/null 2>&1
    docker rm "$app_container" >/dev/null 2>&1

    # Stop and remove the database container
    docker stop "$db_container" >/dev/null 2>&1
    docker rm "$db_container" >/dev/null 2>&1

    # Remove the app image
    docker rmi "$app_image" >/dev/null 2>&1
}

# Argument handling
if [ $# -ne 1 ]; then
    print_message red "❌" "Usage: $0 [test|dev|prod]"
    exit 1
fi

MODE=$1

# Validate mode argument
case $MODE in
    test|dev)
        ENV_FILE=".env.dev"
        ;;
    prod)
        ENV_FILE=".env.prod"
        ;;
    *)
        print_message red "❌" "Invalid mode argument. Please use one of: test, dev, prod"
        exit 1
        ;;
esac

# Check if the environment file exists
if [ ! -f "$ENV_FILE" ]; then
    print_message red "❌" "Environment file $ENV_FILE not found."
    exit 1
fi

# Source the environment file to load variables
source "$ENV_FILE"

# Pull the PostgreSQL image if it doesn't exist and mode is not "test"
if [ "$MODE" != "test" ]; then
    pull_postgres_image
fi

# Stop and remove existing containers and images based on the mode
stop_and_remove

# Step 1: Start the PostgreSQL container
if [ "$MODE" != "test" ]; then
    print_message yellow "🚀" "Starting PostgreSQL container..."
    docker run --name "$DB_CONTAINER_NAME" --env-file "$ENV_FILE" -p "$POSTGRES_PORT":"$POSTGRES_PORT" -v "$(pwd)/postgres-data:/var/lib/postgresql/data" -d "$POSTGRES_IMAGE"

    # Step 2: Wait for PostgreSQL to be ready
    wait_for_postgres
fi

# Step 3: Build Docker image based on the mode using multi-stage builds
print_message yellow "🔨" "Building Docker image for mode: $MODE..."
docker build --no-cache \
    --build-arg ENV_FILE="$ENV_FILE" \
    --target "$MODE" \
    -t "$APP_IMAGE":"$MODE" \
    -f Dockerfile .


# Function to run tests and generate a report
run_tests_and_generate_report() {
    local report_file="test-report-$MODE.txt"

    print_message yellow "🚀" "Running tests for mode: $MODE..."
    docker run --name "$SPRING_BOOT_CONTAINER_NAME-$MODE" --env-file "$ENV_FILE" -p "$APP_PORT":"$APP_PORT" "$APP_IMAGE:$MODE" > "$report_file" 2>&1

    print_message green "✨" "Test report generated: $report_file"
}


# Step 4: Start the Spring Boot application container
print_message yellow "🚀" "Starting Spring Boot application container..."
docker run --name "$SPRING_BOOT_CONTAINER_NAME-$MODE" $([ "$MODE" != "test" ] && echo "--link $DB_CONTAINER_NAME:db") --env-file "$ENV_FILE" -p "$APP_PORT":"$APP_PORT" "$APP_IMAGE:$MODE"

# Print success message and URL
#print_message green "✨" "Application started successfully!"
#if [ "$MODE" != "test" ]; then
#    print_message green "🌐" "Access the application at: http://localhost:$APP_PORT"
#fi
