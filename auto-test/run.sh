#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$ROOT_DIR/auto-test/.tmp/run"
LOG_DIR="$ROOT_DIR/auto-test/.tmp/logs"
PROMPT_FILE="$TEST_DIR/PROMPT.md"
EVENT_LOG="$LOG_DIR/codex-events.jsonl"
LAST_MESSAGE="$LOG_DIR/codex-last-message.txt"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 127
  fi
}

require_command codex
require_command claude
require_command jq
require_command ffmpeg
require_command ffprobe

rm -rf "$TEST_DIR" "$LOG_DIR"
mkdir -p "$TEST_DIR" "$LOG_DIR"

cp "$ROOT_DIR/PROMPT.md" "$TEST_DIR/PROMPT.md"
cp -R "$ROOT_DIR/exampleFolder" "$TEST_DIR/exampleFolder"
cp "$ROOT_DIR/auto-test/transcription.srt" "$TEST_DIR/transcription.srt"
cp "$ROOT_DIR/auto-test/validate.sh" "$TEST_DIR/validate.sh"
chmod +x "$TEST_DIR/exampleFolder/example.sh" "$TEST_DIR/validate.sh"

codex exec \
  --cd "$TEST_DIR" \
  --sandbox danger-full-access \
  --ask-for-approval never \
  --skip-git-repo-check \
  --json \
  --output-last-message "$LAST_MESSAGE" \
  - <"$PROMPT_FILE" \
| tee "$EVENT_LOG"

bash "$TEST_DIR/validate.sh" "$TEST_DIR" | tee "$LOG_DIR/validate.log"

echo "auto-test PASS"
echo "workdir: $TEST_DIR"
echo "logs: $LOG_DIR"
