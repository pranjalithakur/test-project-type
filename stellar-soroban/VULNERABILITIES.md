# Vulnerabilities Guide (Soroban)

- Missing init guard in `init`: contract can be reinitialized if called again.
- Weak admin/owner checks using invoker/tx_source, enabling phishing.
- `approve` lacks owner auth: any caller can set someone else’s allowance.
- `transfer` logs/event publish before state changes; potential reentrancy surface.
- `transfer_from` allowance decrement unchecked to underflow/zero edge behavior.
- `permit` omits domain separation and does not increment nonce (replayable).
- Over-trusting `env.tx_source_account()` for admin in `mint`.
