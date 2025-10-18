#!/bin/bash
set -e

DEPLOY_PATH="/opt/myapp"
CONFIG_PATH="$DEPLOY_PATH/config"
ENVIRONMENT="${1:-default}"
PORT="${2:-9090}"

mkdir -p "$CONFIG_PATH"
chown jenkins:jenkins "$DEPLOY_PATH" -R

# Copy latest JAR
latest_jar=$(ls -t target/*.jar | head -n 1)
cp "$latest_jar" "$DEPLOY_PATH/"

# Copy environment-specific config
if [ "$ENVIRONMENT" = "default" ]; then
    PROPERTIES_FILE="src/main/resources/application.properties"
else
    PROPERTIES_FILE="src/main/resources/application-${ENVIRONMENT}.properties"
fi

if [ -f "$PROPERTIES_FILE" ]; then
    cp "$PROPERTIES_FILE" "$CONFIG_PATH/application.properties"
fi

# Copy systemd service file
sudo cp systemd/booking.service /etc/systemd/system/
sudo systemctl daemon-reload

# Restart the service
sudo systemctl restart booking.service
sudo systemctl status booking.service --no-pager
