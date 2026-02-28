#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

print_help() {
  cat <<'EOF'
Usage:
  scripts/telegram_watch_updates.sh [--clear-webhook] [--timeout SECONDS]

Description:
  Long-polls Telegram updates and prints each update as a compact log line
  including chat_id, username, and message text/data.

Options:
  --clear-webhook      Call deleteWebhook before starting.
  --timeout SECONDS    Long-poll timeout (default: 30).
  -h, --help           Show this help text.
EOF
}

CLEAR_WEBHOOK=false
TIMEOUT_SECONDS=30

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clear-webhook)
      CLEAR_WEBHOOK=true
      shift
      ;;
    --timeout)
      TIMEOUT_SECONDS="${2:-}"
      shift 2
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      print_help >&2
      exit 1
      ;;
  esac
done

if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
  set +a
fi

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
  echo "Missing TELEGRAM_BOT_TOKEN. Set it in ${ROOT_DIR}/.env or export it in your shell." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "This script requires jq. Install jq and try again." >&2
  exit 1
fi

if [[ "${CLEAR_WEBHOOK}" == "true" ]]; then
  curl -sS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/deleteWebhook?drop_pending_updates=false" >/dev/null
fi

echo "Watching Telegram updates. Press Ctrl+C to stop."
offset=""

while true; do
  if [[ -n "${offset}" ]]; then
    UPDATES_JSON="$(curl -sS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?timeout=${TIMEOUT_SECONDS}&offset=${offset}")"
  else
    UPDATES_JSON="$(curl -sS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?timeout=${TIMEOUT_SECONDS}")"
  fi

  if [[ "$(echo "${UPDATES_JSON}" | jq -r '.ok')" != "true" ]]; then
    echo "${UPDATES_JSON}" | jq .
    sleep 2
    continue
  fi

  echo "${UPDATES_JSON}" | jq -c '
    .result[]
    | {
        update_id,
        chat_id: (.message.chat.id // .edited_message.chat.id // .callback_query.message.chat.id // .my_chat_member.chat.id // .chat_member.chat.id),
        username: (.message.from.username // .edited_message.from.username // .callback_query.from.username // "-"),
        text: (.message.text // .edited_message.text // .callback_query.data // "-"),
        type: (
          if .message then "message"
          elif .edited_message then "edited_message"
          elif .callback_query then "callback_query"
          elif .message_reaction then "message_reaction"
          elif .my_chat_member then "my_chat_member"
          elif .chat_member then "chat_member"
          else "other"
          end
        )
      }'

  LAST_UPDATE_ID="$(echo "${UPDATES_JSON}" | jq -r '.result[-1].update_id // empty')"
  if [[ -n "${LAST_UPDATE_ID}" ]]; then
    offset="$((LAST_UPDATE_ID + 1))"
  fi
done
