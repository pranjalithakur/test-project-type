#!/usr/bin/env bash
set -euo pipefail

echo "Building Aptos Move modules..."
aptos move compile

echo "Build complete!" 
