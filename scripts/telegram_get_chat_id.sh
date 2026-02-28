#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

print_help() {
  cat <<'EOF'
Usage:
  scripts/telegram_get_chat_id.sh [--clear-webhook]

Description:
  Fetches recent Telegram updates and prints chat IDs found.
  Also prints the most recent chat ID to use as TELEGRAM_TEST_CHAT_ID.

Options:
  --clear-webhook   Call deleteWebhook first to avoid 409 conflicts.
  -h, --help        Show this help text.
EOF
}

CLEAR_WEBHOOK=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clear-webhook)
      CLEAR_WEBHOOK=true
      shift
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

UPDATES_JSON="$(curl -sS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates")"

if [[ "$(echo "${UPDATES_JSON}" | jq -r '.ok')" != "true" ]]; then
  echo "${UPDATES_JSON}" | jq .
  echo "Telegram API returned an error. If this is a 409 conflict, rerun with --clear-webhook." >&2
  exit 1
fi

echo "Recent chats from getUpdates:"
echo "${UPDATES_JSON}" | jq -r '
  .result
  | map({
      update_id,
      chat_id: (.message.chat.id // .edited_message.chat.id // .callback_query.message.chat.id // .my_chat_member.chat.id // .chat_member.chat.id),
      username: (.message.from.username // .callback_query.from.username // .edited_message.from.username // "-"),
      text: (.message.text // .edited_message.text // .callback_query.data // "-")
    })
  | map(select(.chat_id != null))
  | unique_by(.chat_id)
  | .[]
  | "chat_id=\(.chat_id)\tuser=\(.username)\ttext=\(.text)"'

LATEST_CHAT_ID="$(echo "${UPDATES_JSON}" | jq -r '.result[-1] | (.message.chat.id // .edited_message.chat.id // .callback_query.message.chat.id // .my_chat_member.chat.id // .chat_member.chat.id // empty)')"

if [[ -n "${LATEST_CHAT_ID}" ]]; then
  echo
  echo "Latest chat id:"
  echo "${LATEST_CHAT_ID}"
  echo
  echo "Set this in .env:"
  echo "TELEGRAM_TEST_CHAT_ID=${LATEST_CHAT_ID}"
else
  echo
  echo "No chat_id found yet. Open Telegram, start your bot, send a message, then rerun."
fi
