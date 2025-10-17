#!/bin/bash
set -e

# --- CONFIG ---
DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="${DEPLOY_PATH}/config"

ENVIRONMENT="${1:-default}"    # first argument = environment name
PORT="${2:-9090}"              # second argument = port number

echo "🚀 Starting deployment for environment: $ENVIRONMENT on port $PORT"

# Create directories
mkdir -p "$CONFIG_PATH"
chown jenkins:jenkins "$DEPLOY_PATH" -R

# Find latest JAR
latest_jar=$(ls -t target/*.jar | head -n 1)
echo "Using JAR: $latest_jar"
cp "$latest_jar" "$DEPLOY_PATH/app.jar"

# Select config file
if [ "$ENVIRONMENT" = "default" ]; then
    PROPERTIES_FILE="src/main/resources/application.properties"
    echo "📘 Using default application.properties"
else
    PROPERTIES_FILE="src/main/resources/application-$ENVIRONMENT.properties"
    echo "🌍 Using environment-specific file: $PROPERTIES_FILE"
fi

# Copy properties file if exists
if [ -f "$PROPERTIES_FILE" ]; then
    cp "$PROPERTIES_FILE" "$CONFIG_PATH/application.properties"
    CONFIG_OPTION="--spring.config.location=file:$CONFIG_PATH/application.properties"
else
    echo "⚠️ Config file not found. Using embedded configuration from JAR."
    CONFIG_OPTION=""
fi

# Stop previous app if running
if [ -f "$DEPLOY_PATH/app.pid" ]; then
    echo "🛑 Stopping previous instance..."
    kill "$(cat $DEPLOY_PATH/app.pid)" || true
    rm -f "$DEPLOY_PATH/app.pid"
fi

# Start new app
echo "🚀 Starting new instance..."
nohup setsid java -jar "$DEPLOY_PATH/app.jar" \
    $CONFIG_OPTION \
    --spring.profiles.active="$ENVIRONMENT" \
    --server.port="$PORT" \
    --logging.file.name="$DEPLOY_PATH/app.log" \
    > "$DEPLOY_PATH/nohup.out" 2>&1 < /dev/null &

echo $! > "$DEPLOY_PATH/app.pid"

sleep 5

if ps -p "$(cat $DEPLOY_PATH/app.pid)" > /dev/null; then
    echo "✅ App started successfully (PID $(cat $DEPLOY_PATH/app.pid))"
else
    echo "❌ App failed to start!"
    tail -n 50 "$DEPLOY_PATH/app.log"
    exit 1
fi
