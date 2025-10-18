#!/bin/bash
set -e

DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="$DEPLOY_PATH/config"
LOG_PATH="$DEPLOY_PATH/app.log"

ENVIRONMENT="${1:-default}"
PORT="${2:-9090}"

echo "======================================="
echo "🚀 Local SSH Deploy"
echo "Environment : $ENVIRONMENT"
echo "Port        : $PORT"
echo "Timestamp   : $(date)"
echo "======================================="

# Ensure deploy directories exist
mkdir -p "$CONFIG_PATH"

# Find latest JAR
latest_jar=$(ls -t "$DEPLOY_PATH"/target/*.jar | head -n 1 || true)
if [ -z "$latest_jar" ]; then
    echo "❌ No JAR file found in $DEPLOY_PATH/target"
    exit 1
fi
echo "📦 Using JAR: $latest_jar"
cp "$latest_jar" "$DEPLOY_PATH/app.jar"

# Select properties file
if [ "$ENVIRONMENT" = "default" ]; then
    PROPERTIES_FILE="$DEPLOY_PATH/src/main/resources/application.properties"
else
    PROPERTIES_FILE="$DEPLOY_PATH/src/main/resources/application-$ENVIRONMENT.properties"
fi

# Copy properties file if exists
if [ -f "$PROPERTIES_FILE" ]; then
    cp "$PROPERTIES_FILE" "$CONFIG_PATH/application.properties"
    CONFIG_OPTION="--spring.config.location=file:$CONFIG_PATH/application.properties"
else
    echo "⚠️ Config file not found. Using embedded configuration."
    CONFIG_OPTION=""
fi

# Stop previous instance
if [ -f "$DEPLOY_PATH/app.pid" ]; then
    old_pid=$(cat "$DEPLOY_PATH/app.pid")
    if ps -p "$old_pid" > /dev/null 2>&1; then
        echo "🛑 Stopping previous instance (PID $old_pid)..."
        kill "$old_pid" || true
        sleep 2
    fi
    rm -f "$DEPLOY_PATH/app.pid"
fi

# Start the new instance detached from Jenkins
echo "🚀 Starting new instance..."
nohup java -jar "$DEPLOY_PATH/app.jar" \
    $CONFIG_OPTION \
    --spring.profiles.active="$ENVIRONMENT" \
    --server.port="$PORT" \
    --logging.file.name="$LOG_PATH" \
    > "$DEPLOY_PATH/nohup.out" 2>&1 &

echo $! > "$DEPLOY_PATH/app.pid"
sleep 5

new_pid=$(cat "$DEPLOY_PATH/app.pid")
if ps -p "$new_pid" > /dev/null 2>&1; then
    echo "✅ App started successfully (PID $new_pid)"
else
    echo "❌ App failed to start!"
    tail -n 50 "$LOG_PATH" || true
    exit 1
fi

echo "✅ Deployment complete. Logs at: $LOG_PATH"
