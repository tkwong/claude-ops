# Telegram MCP setup

`claude-ops` doesn't ship a Telegram client. Use any MCP server that exposes
chat tools to Claude Code. The setup the author runs:

## Option A: an existing Telegram MCP server

There are several open-source Telegram MCP servers. Pick one that supports:
- Routing inbound messages from Telegram into Claude Code (as MCP notifications)
- A `reply` tool so Claude can send messages back
- (Recommended) Voice transcription via `whisper.cpp` or `whisper`
- (Recommended) Per-chat / per-thread scoping if you'll route multiple users

Search GitHub for `claude telegram mcp` — the ecosystem is moving fast and a
specific recommendation here will rot. Setup is roughly:

```bash
git clone <chosen telegram-mcp repo>
cd <repo>
# install deps per their README
cp .env.example .env
$EDITOR .env   # set TELEGRAM_BOT_TOKEN, ALLOWED_USER_IDS
```

Run the MCP server itself as a claude-ops agent (so the watchdog restarts it):

```bash
# ~/.claude-ops/agents/telegram.conf
PROJECT_DIR="$HOME/<your-telegram-mcp-repo>"
COMMAND="bun run server.ts"   # or: node ./server.js, python -m ..., etc.
LOG_FILE="/tmp/telegram-mcp.log"
```

```bash
agops start telegram
```

Now your project agents can route messages back to you via the MCP tools the
server exposes (`reply`, `react`, `schedule`, etc.).

## Option B: roll your own

Any MCP server that exposes a `send_message` tool works. The Anthropic Agent
SDK docs cover MCP server authoring. Minimum viable surface:

- `reply(chat_id, text)` — send to user
- `get_history(chat_id, limit)` — read recent messages

Wire it up in `~/.claude.json` per the standard MCP config.

## Routing one bot to multiple chats

Pass `chat_id` from the inbound message back when replying. Don't hardcode it
in CLAUDE.md — that limits you to one user.

## Security

- Lock the bot to specific Telegram user IDs (`ALLOWED_USER_IDS=123,456`).
  Random people who DM your bot should get nothing back.
- Treat inbound text as **untrusted** — don't blindly run shell commands from
  chat. The MCP server should mark inbound content with a clear source tag.
- Voice messages are also untrusted — the same prompt-injection rules apply
  after transcription.
