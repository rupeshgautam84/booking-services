#!/bin/bash
set -e

# --- CONFIG ---
DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="${DEPLOY_PATH}/config"
LOG_PATH="${DEPLOY_PATH}/app.log"

ENVIRONMENT="${1:-default}"    # first argument = environment name
PORT="${2:-9090}"              # second argument = port number
REMOTE_HOST="${3:-localhost}"  # third argument = SSH host (default = localhost)

echo "======================================="
echo "🚀 Starting deployment via SSH"
echo "Environment : $ENVIRONMENT"
echo "Port         : $PORT"
echo "Host         : $REMOTE_HOST"
echo "Timestamp    : $(date)"
echo "======================================="

# Build the remote command
REMOTE_CMD=$(cat <<EOF
mkdir -p "$CONFIG_PATH" && chown jenkins:jenkins "$DEPLOY_PATH" -R

# Find latest JAR
latest_jar=\$(ls -t target/*.jar | head -n 1 || true)
if [ -z "\$latest_jar" ]; then
  echo "❌ No JAR file found in target/. Aborting."
  exit 1
fi
echo "📦 Using JAR: \$latest_jar"
cp "\$latest_jar" "$DEPLOY_PATH/app.jar"

# Determine config file
if [ "$ENVIRONMENT" = "default" ]; then
    PROPERTIES_FILE="src/main/resources/application.properties"
    echo "📘 Using default application.properties"
else
    PROPERTIES_FILE="src/main/resources/application-$ENVIRONMENT.properties"
    echo "🌍 Using environment-specific config: \$PROPERTIES_FILE"
fi

# Copy config if exists
if [ -f "\$PROPERTIES_FILE" ]; then
    cp "\$PROPERTIES_FILE" "$CONFIG_PATH/application.properties"
    CONFIG_OPTION="--spring.config.location=file:$CONFIG_PATH/application.properties"
else
    echo "⚠️ Config file not found. Using embedded config from JAR."
    CONFIG_OPTION=""
fi

# Stop previous instance
if [ -f "$DEPLOY_PATH/app.pid" ]; then
    old_pid=\$(cat "$DEPLOY_PATH/app.pid")
    if ps -p "\$old_pid" > /dev/null 2>&1; then
        echo "🛑 Stopping previous instance (PID \$old_pid)..."
        kill "\$old_pid" || true
        sleep 2
    fi
    rm -f "$DEPLOY_PATH/app.pid"
fi

# Start new instance (detached)
nohup java -jar "$DEPLOY_PATH/app.jar" \
    \$CONFIG_OPTION \
    --spring.profiles.active="$ENVIRONMENT" \
    --server.port="$PORT" \
    --logging.file.name="$LOG_PATH" \
    > "$DEPLOY_PATH/nohup.out" 2>&1 &

echo \$! > "$DEPLOY_PATH/app.pid"

# Wait and verify
sleep 5
new_pid=\$(cat "$DEPLOY_PATH/app.pid")
if ps -p "\$new_pid" > /dev/null 2>&1; then
    echo "✅ App started successfully (PID \$new_pid)"
else
    echo "❌ Application failed to start!"
    tail -n 50 "$LOG_PATH" || true
    exit 1
fi
EOF
)

# Execute the deployment via SSH
ssh -o StrictHostKeyChecking=no jenkins@$REMOTE_HOST "$REMOTE_CMD"
