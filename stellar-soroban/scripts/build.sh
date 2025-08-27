#!/usr/bin/env bash
set -euo pipefail

if command -v soroban >/dev/null 2>&1; then
  soroban contract build
else
  cargo build --release
fi
