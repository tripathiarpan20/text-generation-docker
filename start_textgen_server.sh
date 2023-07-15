#!/usr/bin/env bash

source /workspace/venv/bin/activate
cd /workspace/text-generation-webui
python server.py \
  --listen \
  --api \
  --listen-port 3001 \
  --api-blocking-port 5001 \
  --api-streaming-port 5006