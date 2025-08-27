# Vulnerabilities Guide

This project contains intentionally introduced, realistic vulnerabilities. Use for testing and education only.

## Token.sol
- Manager override in `transferFrom`: `manager` can transfer from any account without allowance.
- Reentrancy surface in `_beforeTokenTransfer`: external hook called before effects.
- Permit without nonce/deadline/domain: replayable across chains and sessions.
- `increaseAllowance` unchecked math: allowance wrap risks when using `unchecked`.

## AccessManager.sol
- `onlyAdmin` uses `tx.origin`: phishable authorization; breaks meta-tx.
- `grantRoleBySig` replayable: lacks nonce, deadline, and domain separation.
- `onTransfer` can reenter token and mint during hooks.

## Oracle.sol
- `setFeeder` lacks access control: anyone can rotate the feeder.
- `submitPrice` allows non-feeder updates when stale: price can be pushed by anyone.

## Vault.sol
- `withdraw` external call before effects: reentrancy window on accounting.
- Share math initialization/donation edge: first depositor and donation attacks.
- `setOracle` uses `tx.origin`: weak ownership check.
- `execute` uses `delegatecall` with loose auth and silent failures.
- Oracle trust: `maxWithdrawValue` trusts `getPrice()` without sanity checks.

There are well over five distinct issues across the system; auditors should examine cross-contract interactions, authorization patterns, and call ordering.
