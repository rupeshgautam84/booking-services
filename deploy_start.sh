#!/bin/bash
set -e

ENVIRONMENT=${1:-default}
PORT=${2:-9090}
DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="$DEPLOY_PATH/config"

echo "🚀 Starting application..."
mkdir -p "$CONFIG_PATH"

latest_jar=$(ls -t $DEPLOY_PATH/target/*.jar | head -n 1)
cp "$latest_jar" "$DEPLOY_PATH/app.jar"

if [ "$ENVIRONMENT" != "default" ]; then
    cp "$DEPLOY_PATH/src/main/resources/application-$ENVIRONMENT.properties" "$CONFIG_PATH/application.properties"
    CONFIG_OPTION="--spring.config.location=file:$CONFIG_PATH/application.properties"
else
    CONFIG_OPTION=""
fi

# Stop any existing instance before starting new
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
