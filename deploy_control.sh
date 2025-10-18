#!/bin/bash
set -e

ACTION=$1
DEPLOY_PATH="/opt/myapp"

if [ -z "$ACTION" ]; then
    echo "Usage: $0 stop|status"
    exit 1
fi

# --- STOP LOGIC ---
if [ "$ACTION" == "stop" ]; then
    echo "🛑 Stopping the application..."
    if [ -f "$DEPLOY_PATH/app.pid" ]; then
        PID=$(cat "$DEPLOY_PATH/app.pid")
        if ps -p $PID > /dev/null 2>&1; then
            echo "➡️ Killing PID $PID..."
            kill $PID || true
            echo "✅ Application stopped (PID=$PID)"
        else
            echo "⚠️ PID file exists but process not running"
        fi
        rm -f "$DEPLOY_PATH/app.pid"
    else
        echo "ℹ️ No running instance found"
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

echo "❌ Unknown action: $ACTION"
exit 1
