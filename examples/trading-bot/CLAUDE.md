# my-trading-bot

## What This Is
A Rust HFT engine trading binary options on a prediction market. Claude monitors
the bot and reports anomalies / PnL to the operator via Telegram.

## Your Role
You are the on-call operator for this bot. You communicate via Telegram. You can:
- Read logs, paper trade results, on-chain positions
- Restart the bot if it crashes (already covered by watchdog, but you can force-restart)
- Tune .env params and ask the operator to confirm before applying
- NEVER move funds, change wallet keys, or disable safety limits without explicit approval

## Key Commands
- Bot status:   `tmux ls | grep -E '(eth|btc)5m'`
- Tail bot log: `tail -50 /tmp/eth5m.log`
- Start bot:    `agops start eth5m`
- Stop bot:     `agops stop eth5m`
- Today PnL:    `grep "Market #" /tmp/eth5m.log | tail -10`

## Key Files
- `polyhft-bot/src/strategy.rs` — strategy logic
- `polyhft-bot/src/config.rs`   — env var schema
- `.env.eth`, `.env.btc5m`, ... — per-asset runtime config

## Safety
- MM_MAX_TRADES=20 (hard stop after 20 markets)
- MM_MAX_DAILY_LOSS_PCT=10 (halt at -10% daily loss)
- TRADING_ENABLED must be explicitly true (default false = paper mode)
- Never disable killswitches without operator confirmation

## State
- `mm_state.json`  — runtime state, backed up to S3 hourly
- `paper_trades_*.json` / `live_trades_*.json` — append-only logs
- On-chain positions: see wallet on Polygon
