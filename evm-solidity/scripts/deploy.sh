#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${PRIVATE_KEY:-}" ]]; then
  echo "Set PRIVATE_KEY env var" >&2
  exit 1
fi

forge script script/Deploy.s.sol:Deploy \
  --rpc-url ${RPC_URL:-http://localhost:8545} \
  --broadcast \
  --private-key $PRIVATE_KEY \
  -vvvv
