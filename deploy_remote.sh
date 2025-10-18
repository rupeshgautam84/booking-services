#!/bin/bash
set -e

DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="${DEPLOY_PATH}/config"
LOG_PATH="${DEPLOY_PATH}/app.log"

ACTION="${1:-start}"         # start or stop
ENVIRONMENT="${2:-default}"  # environment
PORT="${3:-9090}"            # port

echo "======================================="
echo "Action      : $ACTION"
echo "Environment : $ENVIRONMENT"
echo "Port        : $PORT"
echo "Timestamp   : $(date)"
echo "======================================="

mkdir -p "$CONFIG_PATH"
chown jenkins:jenkins "$DEPLOY_PATH" -R

# Stop the app if requested
if [ "$ACTION" == "stop" ]; then
    if [ -f "$DEPLOY_PATH/app.pid" ]; then
        old_pid=$(cat "$DEPLOY_PATH/app.pid")
        if ps -p "$old_pid" > /dev/null 2>&1; then
            echo "🛑 Stopping application (PID $old_pid)..."
            kill "$old_pid" || true
            sleep 2
        fi
        rm -f "$DEPLOY_PATH/app.pid"
    else
        echo "⚠️ No running application found."
    fi
    echo "✅ Application stopped."
    exit 0
fi

# --- Start the app ---
# Find latest JAR
latest_jar=$(ls -t target/*.jar | head -n 1 || true)
if [ -z "$latest_jar" ]; then
    echo "❌ No JAR file found in target/. Aborting."
    exit 1
fi
echo "📦 Using JAR: $latest_jar"
cp "$latest_jar" "$DEPLOY_PATH/app.jar"

# Handle config
if [ "$ENVIRONMENT" = "default" ]; then
    PROPERTIES_FILE="src/main/resources/application.properties"
    CONFIG_OPTION=""
else
    PROPERTIES_FILE="src/main/resources/application-$ENVIRONMENT.properties"
    if [ -f "$PROPERTIES_FILE" ]; then
        cp "$PROPERTIES_FILE" "$CONFIG_PATH/application.properties"
        CONFIG_OPTION="--spring.config.location=file:$CONFIG_PATH/application.properties"
    else
        echo "⚠️ Config file not found. Using embedded config from JAR."
        CONFIG_OPTION=""
    fi
fi

# Stop previous app if running
if [ -f "$DEPLOY_PATH/app.pid" ]; then
    old_pid=$(cat "$DEPLOY_PATH/app.pid")
    if ps -p "$old_pid" > /dev/null 2>&1; then
        echo "🛑 Stopping previous instance (PID $old_pid)..."
        kill "$old_pid" || true
        sleep 2
    fi
    rm -f "$DEPLOY_PATH/app.pid"
fi

# Start the app fully detached
echo "🚀 Launching new application..."
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
    echo "✅ Application started successfully (PID $new_pid)"
else
    echo "❌ Application failed to start!"
    tail -n 50 "$LOG_PATH" || true
    exit 1
fi

echo "✅ Deployment complete. Logs at: $LOG_PATH"
