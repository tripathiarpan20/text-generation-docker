#!/usr/bin/env bash

ARGS=("$@" --listen --api --listen-port 3001 --api-blocking-port 5001 --api-streaming-port 5006)
source /workspace/venv/bin/activate
cd /workspace/text-generation-webui
echo "Starting Oobabooba Text Generation UI: ${ARGS[@]}"
python3 server.py "${ARGS[@]}"