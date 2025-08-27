#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${APTOS_PROFILE:-}" ]]; then
  echo "Set APTOS_PROFILE env var" >&2
  exit 1
fi

echo "Publishing Aptos Move modules..."
aptos move publish --profile $APTOS_PROFILE

echo "Publish complete!" 
