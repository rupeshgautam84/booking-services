#!/bin/bash
set -euo pipefail

ACTION=${1:-start}
ENVIRONMENT=${2:-default}
PORT=${3:-9090}

DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="${DEPLOY_PATH}/config"
JAR_PATH="$DEPLOY_PATH/target"
LOG_FILE="$DEPLOY_PATH/app.log"
PID_FILE="$DEPLOY_PATH/app.pid"

echo "======================================="
echo "🌀 Action      : $ACTION"
echo "🌍 Environment : $ENVIRONMENT"
echo "🔌 Port        : $PORT"
echo "📁 Deploy Path : $DEPLOY_PATH"
echo "======================================="

# --- STATUS CHECK FUNCTION ---
status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "✅ Application is running (PID: $PID)"
            return 0
        else
            echo "⚠️ PID file exists but process is not running."
            return 1
        fi
    else
        echo "ℹ️ No PID file found. Application not running."
        return 1
    fi
}

# --- STOP LOGIC ---
if [ "$ACTION" == "stop" ]; then
    echo "🛑 Attempting to stop the running application..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "➡️ Stopping app with PID $PID..."
            kill "$PID" || true
            sleep 2
            if ps -p $PID > /dev/null 2>&1; then
                echo "⚠️ Force killing PID $PID..."
                kill -9 "$PID" || true
            fi
            echo "✅ Application stopped successfully."
        else
            echo "⚠️ PID file found but no running process. Cleaning up..."
        fi
        rm -f "$PID_FILE"
    else
        echo "ℹ️ No running instance found. Nothing to stop."
    fi
    exit 0
fi

# --- STATUS LOGIC ---
if [ "$ACTION" == "status" ]; then
    status
    exit 0
fi

# --- START LOGIC ---
echo "🚀 Starting application..."
mkdir -p "$CONFIG_PATH"

latest_jar=$(ls -t "$JAR_PATH"/*.jar 2>/dev/null | head -n 1 || true)
if [ -z "$latest_jar" ]; then
    echo "❌ ERROR: No JAR found in $JAR_PATH"
    exit 1
fi

cp "$latest_jar" "$DEPLOY_PATH/app.jar"

if [ "$ENVIRONMENT" != "default" ]; then
    if [ -f "$DEPLOY_PATH/src/main/resources/application-$ENVIRONMENT.properties" ]; then
        cp "$DEPLOY_PATH/src/main/resources/application-$ENVIRONMENT.properties" "$CONFIG_PATH/application.properties"
        CONFIG_OPTION="--spring.config.location=file:$CONFIG_PATH/application.properties"
    else
        echo "⚠️ application-$ENVIRONMENT.properties not found. Using default config."
        CONFIG_OPTION=""
    fi
else
    CONFIG_OPTION=""
fi

# Stop existing process before starting new
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p $OLD_PID > /dev/null 2>&1; then
        echo "⚠️ Stopping existing app (PID=$OLD_PID)..."
        kill "$OLD_PID" || true
        sleep 2
    fi
    rm -f "$PID_FILE"
fi

nohup java -jar "$DEPLOY_PATH/app.jar" \
    $CONFIG_OPTION \
    --spring.profiles.active="$ENVIRONMENT" \
    --server.port="$PORT" \
    --logging.file.name="$LOG_FILE" \
    > "$DEPLOY_PATH/nohup.out" 2>&1 &

echo $! > "$PID_FILE"
echo "✅ Application started successfully (PID=$(cat "$PID_FILE"))"
echo "📜 Logs: $LOG_FILE"
