#!/bin/bash
set -euo pipefail

# Safely export variables from .env file
while IFS='=' read -r key value; do
  if [[ ! "$key" =~ ^# ]] && [[ -n "$key" ]]; then
    export "$key"="$value"
  fi
done < .env