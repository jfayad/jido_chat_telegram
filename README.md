# Jido Chat Telegram

`jido_chat_telegram` is the Telegram adapter package for `jido_chat`.

## Experimental Status

This package is experimental and pre-1.0. APIs and behavior will change.
It is part of the Elixir implementation aligned to the Vercel Chat SDK
([chat-sdk.dev/docs](https://www.chat-sdk.dev/docs)).

`Jido.Chat.Telegram.Adapter` is the canonical adapter module and uses `ExGram` as the Telegram client.

`Jido.Chat.Telegram.Channel` is kept as a compatibility wrapper for legacy `Jido.Chat.Channel` integrations.
No Telegex dependency is required.

## Installation

```elixir
def deps do
  [
    {:jido_chat, github: "agentjido/jido_chat", branch: "main"},
    {:jido_chat_telegram, github: "agentjido/jido_chat_telegram", branch: "main"}
  ]
end
```

## Usage

```elixir
alias Jido.Chat.Telegram.Adapter

{:ok, incoming} =
  Adapter.transform_incoming(%{
    "message" => %{
      "message_id" => 42,
      "date" => 1_706_745_600,
      "chat" => %{"id" => 123, "type" => "private"},
      "from" => %{"id" => 99, "first_name" => "Alice"},
      "text" => "hello"
    }
  })

{:ok, sent} =
  Adapter.send_message(123, "hi", token: System.fetch_env!("TELEGRAM_BOT_TOKEN"))
```

`ExGram` is used under the hood, with a Req-backed adapter by default.

## Telegram Extension Surface

For Telegram-specific features that are intentionally outside core `Jido.Chat.Adapter`,
use `Jido.Chat.Telegram.Extensions`:

```elixir
alias Jido.Chat.Telegram.Extensions

# Telegram-only media send helpers
{:ok, photo} =
  Extensions.send_photo(123, "AgACAg...", token: System.fetch_env!("TELEGRAM_BOT_TOKEN"))

{:ok, document} =
  Extensions.send_document(123, "BQACAg...", token: System.fetch_env!("TELEGRAM_BOT_TOKEN"))

# Telegram-only callback query answer helper
:ok =
  Extensions.answer_callback_query("1234567890", token: System.fetch_env!("TELEGRAM_BOT_TOKEN"))
  |> case do
    {:ok, _result} -> :ok
    other -> other
  end
```

Typed extension structs are provided for:

- `Jido.Chat.Telegram.UpdateEnvelope`
- `Jido.Chat.Telegram.CallbackQuery`
- `Jido.Chat.Telegram.InlineKeyboard` / `InlineKeyboardButton`
- `Jido.Chat.Telegram.MediaMessage`

## Config

You can pass `:token` per call, or configure globally:

```elixir
config :jido_chat_telegram, :telegram_bot_token, System.get_env("TELEGRAM_BOT_TOKEN")
```

For tests, this package will automatically load `.env` and `.env.test` via `dotenvy`
from `test/test_helper.exs`.

## Ingress Modes (`listener_child_specs/2`)

`Jido.Chat.Telegram.Adapter.listener_child_specs/2` supports:

- `ingress.mode = "webhook"`: no listener workers (`{:ok, []}`), host HTTP handles webhook ingress.
- `ingress.mode = "polling"`: starts `PollingWorker` and emits updates via `sink_mfa`.

Example:

```elixir
{:ok, specs} =
  Jido.Chat.Telegram.Adapter.listener_child_specs("bridge_tg",
    ingress: %{mode: "polling", token: System.fetch_env!("TELEGRAM_BOT_TOKEN")},
    sink_mfa: {Jido.Messaging.IngressSink, :emit, [MyApp.Messaging, "bridge_tg"]}
  )
```

## Live Integration Test

There is a live test module at:

- `test/jido/chat/telegram/live_integration_test.exs`

It is skipped by default. To run it:

1. Start a private chat with your bot and send at least one message (`/start` is fine).
2. Copy and fill local env file:

```bash
cp .env.example .env
```

3. Run:

```bash
mix test test/jido/chat/telegram/live_integration_test.exs
```

If you need `TELEGRAM_TEST_CHAT_ID`, use the helper script:

```bash
scripts/telegram_get_chat_id.sh --clear-webhook
```

For live update logs while chatting with your bot from Telegram:

```bash
scripts/telegram_watch_updates.sh --clear-webhook
```

Additional helper:

- `scripts/telegram_delete_webhook.sh`
