# Vulnerabilities Guide (Solana Anchor)

- Missing re-initialization guard in `initialize` allows state overwrite if PDA reused.
- `withdraw` performs CPI before state update: reentrancy window via CPI-capable programs.
- `set_admin` authorizes by payer instead of admin signer account.
- `exec` allows arbitrary CPI/data flow with weak constraints: account confusion potential.
- No freeze/paused checks across instructions; no authority change two-step.
- No rate limits; `total_deposits` can desync via donation/ATA confusion.
