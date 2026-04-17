# Telegram MCP setup

`claude-ops` doesn't ship a Telegram client. Use any MCP server that exposes
chat tools to Claude Code. The setup the author runs:

## Option A: claude-telegram-supercharged

[github.com/.../claude-telegram-supercharged](https://github.com/) — a TypeScript
MCP server that:
- Routes Telegram chats to Claude Code sessions
- Auto-transcribes voice messages (whisper.cpp)
- Schedules reminders / cron jobs from chat
- Multi-chat / multi-thread routing

Setup:
```bash
git clone https://github.com/.../claude-telegram-supercharged.git
cd claude-telegram-supercharged
bun install
cp .env.example .env
$EDITOR .env   # set TELEGRAM_BOT_TOKEN, ALLOWED_USER_IDS
```

Run it as a claude-ops agent itself:

```bash
# ~/.claude-ops/agents/telegram.conf
PROJECT_DIR="$HOME/claude-telegram-supercharged"
COMMAND="bun run server.ts"
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
