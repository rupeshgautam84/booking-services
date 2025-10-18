#!/bin/bash
set -e

ACTION=$1
ENVIRONMENT=${2:-default}
PORT=${3:-9090}

DEPLOY_PATH="/opt/myapp"

if [ "$ACTION" == "start" ]; then
    bash "$DEPLOY_PATH/deploy_start.sh" "$ENVIRONMENT" "$PORT"
elif [ "$ACTION" == "stop" ] || [ "$ACTION" == "status" ]; then
    bash "$DEPLOY_PATH/deploy_control.sh" "$ACTION"
else
    echo "❌ Unknown action: $ACTION"
    exit 1
fi
