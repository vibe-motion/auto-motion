#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"
SCENE_DIR="$ROOT_DIR/scenes/scene-001"
SCENE_MP4="$SCENE_DIR/scene-001.mp4"
FINAL_MP4="$ROOT_DIR/final.mp4"
DESIGN_MD="$SCENE_DIR/design.md"
USER_LOG="$SCENE_DIR/claude-scene-001.user.log"

fail() {
  echo "auto-test FAIL: $*" >&2
  exit 1
}

require_file() {
  local file="$1"
  [[ -s "$file" ]] || fail "missing or empty file: $file"
}

within_range() {
  local value="$1"
  local min="$2"
  local max="$3"
  awk -v value="$value" -v min="$min" -v max="$max" 'BEGIN { exit !((value + 0) >= min && (value + 0) <= max) }'
}

probe_json() {
  local file="$1"
  ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=width,height,avg_frame_rate,r_frame_rate,duration \
    -show_entries format=duration \
    -of json \
    "$file"
}

check_video_specs() {
  local file="$1"
  local json width height fps_raw fps duration audio_count

  require_file "$file"
  json="$(probe_json "$file")"
  width="$(jq -r '.streams[0].width // 0' <<<"$json")"
  height="$(jq -r '.streams[0].height // 0' <<<"$json")"
  fps_raw="$(jq -r '.streams[0].avg_frame_rate // .streams[0].r_frame_rate // "0/0"' <<<"$json")"
  duration="$(jq -r '.format.duration // .streams[0].duration // 0' <<<"$json")"
  fps="$(awk -F/ 'BEGIN { fps = 0 } $2 > 0 { fps = $1 / $2 } END { printf "%.3f", fps }' <<<"$fps_raw")"
  audio_count="$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$file" | awk 'END { print NR }')"

  [[ "$width" == "1080" ]] || fail "$file width is $width, expected 1080"
  [[ "$height" == "1440" ]] || fail "$file height is $height, expected 1440"
  within_range "$fps" 29.8 30.2 || fail "$file fps is $fps, expected 30"
  within_range "$duration" 0.85 1.25 || fail "$file duration is $duration, expected about 1 second"
  [[ "$audio_count" == "0" ]] || fail "$file has $audio_count audio stream(s), expected none"
}

require_file "$DESIGN_MD"
if grep -q "由 Claude 子 agent 用中文填写" "$DESIGN_MD"; then
  fail "design.md still contains the template placeholder"
fi

require_file "$USER_LOG"
grep -q "需求理解和素材检查已完成" "$USER_LOG" || fail "missing progress message: requirement check"
grep -q "设计已写入 design.md" "$USER_LOG" || fail "missing progress message: design"
grep -q "代码已完成，开始自检" "$USER_LOG" || fail "missing progress message: code complete"
grep -q "自检通过，开始渲染" "$USER_LOG" || fail "missing progress message: render start"
grep -q "视频已渲染完成：scene-001.mp4" "$USER_LOG" || fail "missing progress message: render complete"

check_video_specs "$SCENE_MP4"
check_video_specs "$FINAL_MP4"

echo "auto-test PASS: final.mp4 is 1080x1440, 30fps, about 1s, silent, and stage messages are complete."
