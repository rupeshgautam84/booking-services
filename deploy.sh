#!/bin/bash
set -e

# --- CONFIG ---
DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="${DEPLOY_PATH}/config"

ENVIRONMENT="${1:-default}"    # first argument = environment name
PORT="${2:-9090}"              # second argument = port number

echo "======================================="
echo "🚀 Starting deployment"
echo "Environment : $ENVIRONMENT"
echo "Port         : $PORT"
echo "Timestamp    : $(date)"
echo "======================================="

# Create directories
mkdir -p "$CONFIG_PATH"
chown jenkins:jenkins "$DEPLOY_PATH" -R

# Find latest JAR
latest_jar=$(ls -t target/*.jar | head -n 1 || true)
if [ -z "$latest_jar" ]; then
  echo "❌ No JAR file found in target/. Aborting."
  exit 1
fi
echo "📦 Using JAR: $latest_jar"
cp "$latest_jar" "$DEPLOY_PATH/app.jar"

# Determine config file
if [ "$ENVIRONMENT" = "default" ]; then
    PROPERTIES_FILE="src/main/resources/application.properties"
    echo "📘 Using default application.properties"
else
    PROPERTIES_FILE="src/main/resources/application-${ENVIRONMENT}.properties"
    echo "🌍 Using environment-specific config: $PROPERTIES_FILE"
fi

# Copy config if it exists
if [ -f "$PROPERTIES_FILE" ]; then
    cp "$PROPERTIES_FILE" "$CONFIG_PATH/application.properties"
    CONFIG_OPTION="--spring.config.location=file:$CONFIG_PATH/application.properties"
else
    echo "⚠️ Config file not found. Using embedded config from JAR."
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

# --- START NEW INSTANCE ---
echo "🚀 Launching new instance fully detached from Jenkins..."

# run Java in a separate session that won't die when Jenkins closes the shell
nohup setsid bash -c "
  java -jar '$DEPLOY_PATH/app.jar' \
      $CONFIG_OPTION \
      --spring.profiles.active='$ENVIRONMENT' \
      --server.port='$PORT' \
      --logging.file.name='$DEPLOY_PATH/app.log' \
      > '$DEPLOY_PATH/nohup.out' 2>&1 &
  echo \$! > '$DEPLOY_PATH/app.pid'
" >/dev/null 2>&1 < /dev/null &

sleep 5

# --- VERIFY STARTUP ---
if [ -f "$DEPLOY_PATH/app.pid" ]; then
  new_pid=$(cat "$DEPLOY_PATH/app.pid")
  if ps -p "$new_pid" > /dev/null 2>&1; then
      echo "✅ App
