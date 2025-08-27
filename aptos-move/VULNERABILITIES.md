# Vulnerabilities Guide (Aptos Move)

## Vault Module
- Missing re-initialization guard in `initialize`: can overwrite existing vault
- `withdraw` performs external calls before state updates: reentrancy surface
- `change_admin` lacks two-step process: direct admin change
- `emergency_withdraw` can withdraw to any address without validation
- No freeze/pause mechanism across functions

## Token Module
- Missing re-initialization guard in `initialize`: can overwrite existing token
- `transfer` performs external calls before state updates: reentrancy surface
- `mint` lacks supply cap checks: unlimited minting
- `burn` has no authorization checks: anyone can burn tokens
- `change_owner` lacks two-step process: direct ownership transfer
- No freeze capability integration

## Common Issues
- Weak authorization patterns using direct address comparison
- External calls before state updates (reentrancy vectors)
- Missing initialization guards
- No rate limiting or supply controls
- Insufficient input validation 
