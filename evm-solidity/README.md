# EVM Solidity (Foundry)

Deliberately vulnerable contracts for security testing and education. Not for production use.

## Stack
- Foundry (forge, cast)
- Solidity 0.8.20

## Contracts
- `Token.sol`: ERC20-like token with manager hooks and a minimal permit.
- `AccessManager.sol`: Admin/role helper and token transfer hook.
- `Oracle.sol`: Minimal price oracle.
- `Vault.sol`: Token vault with share accounting and oracle integration.

## Quickstart
```bash
# install foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# build
./scripts/build.sh

# deploy (requires PRIVATE_KEY and optional RPC_URL)
export PRIVATE_KEY=0x...
export RPC_URL=https://...
./scripts/deploy.sh
```

See `VULNERABILITIES.md` for intentionally included issues.
