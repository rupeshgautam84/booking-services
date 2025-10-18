#!/bin/bash
set -e

ACTION=$1
ENVIRONMENT=${2:-default}
PORT=${3:-9090}
DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="${DEPLOY_PATH}/config"

echo "🌀 Action: $ACTION | Environment: $ENVIRONMENT | Port: $PORT"

# --- STOP LOGIC ---
if [ "$ACTION" == "stop" ]; then
    echo "🛑 Attempting to stop the running application..."
    if [ -f "$DEPLOY_PATH/app.pid" ]; then
        PID=$(cat "$DEPLOY_PATH/app.pid")
        if ps -p $PID > /dev/null 2>&1; then
            echo "➡️ Stopping app with PID $PID..."
            kill $PID || true
            rm -f "$DEPLOY_PATH/app.pid"
            echo "✅ Application stopped successfully."
        else
            echo "⚠️ PID file found but process not running. Cleaning up..."
            rm -f "$DEPLOY_PATH/app.pid"
        fi
    else
        echo "ℹ️ No running instance found. Nothing to stop."
    fi
    exit 0
fi

# --- STATUS LOGIC ---
if [ "$ACTION" == "status" ]; then
    if [ -f "$DEPLOY_PATH/app.pid" ]; then
        PID=$(cat "$DEPLOY_PATH/app.pid")
        if ps -p $PID > /dev/null 2>&1; then
            echo "ℹ️ Application is running (PID=$PID)"
        else
            echo "⚠️ PID file exists but process not running"
        fi
    else
        echo "ℹ️ Application is not running"
    fi
    exit 0
fi

# --- START LOGIC ---
echo "🚀 Starting application..."
mkdir -p "$CONFIG_PATH"

# Find latest JAR
latest_jar=$(ls -t $DEPLOY_PATH/target/*.jar | head -n 1)
cp "$latest_jar" "$DEPLOY_PATH/app.jar"

# Copy environment-specific config if needed
CONFIG_OPTION=""
if [ "$ENVIRONMENT" != "default" ]; then
    if [ -f "$DEPLOY_PATH/src/main/resources/application-$ENVIRONMENT.properties" ]; then
        cp "$DEPLOY_PATH/src/main/resources/application-$ENVIRONMENT.properties" "$CONFIG_PATH/application.properties"
        CONFIG_OPTION="--spring.config.location=file:$CONFIG_PATH/application.properties"
    else
        echo "⚠️ Config file for environment '$ENVIRONMENT' not found. Using default configuration."
    fi
fi

# Stop any running instance before starting new
if [ -f "$DEPLOY_PATH/app.pid" ]; then
    OLD_PID=$(cat "$DEPLOY_PATH/app.pid")
    if ps -p $OLD_PID > /dev/null 2>&1; then
        echo "⚠️ Stopping existing app (PID=$OLD_PID)..."
        kill $OLD_PID || true
    fi
    rm -f "$DEPLOY_PATH/app.pid"
fi

nohup java -jar "$DEPLOY_PATH/app.jar" \
    $CONFIG_OPTION \
    --spring.profiles.active="$ENVIRONMENT" \
    --server.port="$PORT" \
    --logging.file.name="$DEPLOY_PATH/app.log" \
    > "$DEPLOY_PATH/nohup.out" 2>&1 &

echo $! > "$DEPLOY_PATH/app.pid"
echo "✅ Application started successfully (PID=$(cat $DEPLOY_PATH/app.pid))"
