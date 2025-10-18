#!/bin/bash
set -e

ACTION=$1
ENVIRONMENT=${2:-default}
PORT=${3:-9090}
DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="${DEPLOY_PATH}/config"

if [ "$ACTION" == "stop" ]; then
    echo "🛑 Stopping application..."
    if [ -f "$DEPLOY_PATH/app.pid" ]; then
        kill $(cat "$DEPLOY_PATH/app.pid") || true
        rm -f "$DEPLOY_PATH/app.pid"
        echo "✅ Application stopped."
    else
        echo "⚠️ No running app found."
    fi
    exit 0
fi

echo "🚀 Starting application with ENV=$ENVIRONMENT PORT=$PORT"
mkdir -p "$CONFIG_PATH"

latest_jar=$(ls -t $DEPLOY_PATH/target/*.jar | head -n 1)
cp "$latest_jar" "$DEPLOY_PATH/app.jar"

if [ "$ENVIRONMENT" != "default" ]; then
    cp "$DEPLOY_PATH/src/main/resources/application-$ENVIRONMENT.properties" "$CONFIG_PATH/application.properties"
    CONFIG_OPTION="--spring.config.location=file:$CONFIG_PATH/application.properties"
else
    CONFIG_OPTION=""
fi

if [ -f "$DEPLOY_PATH/app.pid" ]; then
    kill $(cat "$DEPLOY_PATH/app.pid") || true
    rm -f "$DEPLOY_PATH/app.pid"
fi

nohup java -jar "$DEPLOY_PATH/app.jar" \
    $CONFIG_OPTION \
    --spring.profiles.active="$ENVIRONMENT" \
    --server.port="$PORT" \
    --logging.file.name="$DEPLOY_PATH/app.log" \
    > "$DEPLOY_PATH/nohup.out" 2>&1 &

echo $! > "$DEPLOY_PATH/app.pid"
echo "✅ Application started successfully (PID=$(cat $DEPLOY_PATH/app.pid))."
