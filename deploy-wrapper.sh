#!/bin/bash

DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="$DEPLOY_PATH/config"
ENVIRONMENT="${1:-default}"
PORT="${2:-9090}"

# Find the latest JAR in the deploy folder
latest_jar=$(ls -t $DEPLOY_PATH/*.jar | head -n 1)
if [ -z "$latest_jar" ]; then
    echo "❌ No JAR found in $DEPLOY_PATH"
    exit 1
fi

# Run the JAR
exec java -jar "$latest_jar" \
    --spring.profiles.active="$ENVIRONMENT" \
    --server.port="$PORT" \
    --spring.config.location=file:$CONFIG_PATH/application.properties
