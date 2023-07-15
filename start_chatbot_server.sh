#!/usr/bin/env bash

source /workspace/venv/bin/activate
cd /workspace/text-generation-webui
python server.py --listen --listen-port 3001 --api --chat