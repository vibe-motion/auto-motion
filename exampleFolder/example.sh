#!/usr/bin/env bash
set -euo pipefail

# Fill these values before running, or override them with environment variables.
SCENE_ID="${SCENE_ID:-scene-001}"
SCENE_DURATION_SECONDS="${SCENE_DURATION_SECONDS:-TODO_SECONDS}"
OUTPUT_FILE="${OUTPUT_FILE:-${SCENE_ID}.mp4}"
FULL_TRANSCRIPT_PATH="${FULL_TRANSCRIPT_PATH:-transcription.srt}"

if [[ -z "${SCENE_TEXT:-}" ]]; then
  SCENE_TEXT="$(cat <<'TEXT_EOF'
TODO: Paste the subtitle text assigned to this scene.
TEXT_EOF
)"
fi

RAW_LOG="${RAW_LOG:-claude-${SCENE_ID}.stream.jsonl}"
STDERR_LOG="${STDERR_LOG:-claude-${SCENE_ID}.stderr.log}"
USER_LOG="${USER_LOG:-claude-${SCENE_ID}.user.log}"

if [[ "$SCENE_DURATION_SECONDS" == "TODO_SECONDS" || "$SCENE_TEXT" == TODO:* ]]; then
  echo "Please fill SCENE_DURATION_SECONDS and SCENE_TEXT before running." >&2
  exit 2
fi

: >"$RAW_LOG"
: >"$STDERR_LOG"
: >"$USER_LOG"

PROMPT="$(cat <<PROMPT_EOF
你是一个非交互式 coding agent，当前只负责一个镜头的 MG 动画制作。

任务目标：
1. 根据镜头文案和时长，设计 1080x1440、30fps、静音、无音轨的 MG 动画。
2. 使用 hyperframes 编写代码、自检并渲染 mp4。
3. 覆盖写入 design.md，不保留模板占位文本。
4. 最终 mp4 必须输出为：${OUTPUT_FILE}
5. 不要向用户提问；直接写文件、运行检查、渲染并交付结果。

镜头信息：
- 镜头编号：${SCENE_ID}
- 镜头时长：${SCENE_DURATION_SECONDS} 秒
- 输出文件：${OUTPUT_FILE}
- 完整字幕文件：${FULL_TRANSCRIPT_PATH}
- 镜头文案：
${SCENE_TEXT}

上下文使用规则：
- 如果 ${FULL_TRANSCRIPT_PATH} 存在，请先阅读它，用于理解当前镜头在完整文案中的语义位置。
- 不需要把字幕文案逐字放进画面；可使用图形、图标、概念性文字或少量标签表达含义。
- 如果专业名词、品牌、产品或机构名称含义不清，可以联网搜索；如存在明确 logo 或品牌视觉资产，优先用 logo 或抽象化品牌图形表达。

实现要求：
- 使用 hyperframes 完成实现和渲染，可结合 GSAP 等动效库。
- 动画必须可按任意帧独立计算，避免依赖渲染顺序、Date.now()、运行时随机数或运行时网络请求。
- 视觉复杂度服务于文案，不要为了炫技拉长开发和渲染时间。
- 渲染完成后，如 hyperframes 输出在 renders/ 等目录，请复制或转存为当前目录下的 ${OUTPUT_FILE}。

阶段性汇报规则：
- 关键阶段完成时，单独输出一行以 [[USER_MESSAGE]] 开头的消息。
- 不要等所有代码写完才汇报；每完成一个明确阶段就输出一次。
- 如果某个阶段预计超过 60 秒，完成有意义子步骤后输出：[[USER_MESSAGE]]进行中：<当前阶段和已完成内容>
- 除这些关键消息外，不要输出其他用户可见进度文本。

必须至少输出以下阶段消息，文字保持一致：
[[USER_MESSAGE]]需求理解和素材检查已完成
[[USER_MESSAGE]]设计已写入 design.md
[[USER_MESSAGE]]代码已完成，开始自检
[[USER_MESSAGE]]自检通过，开始渲染
[[USER_MESSAGE]]视频已渲染完成：${OUTPUT_FILE}
PROMPT_EOF
)"

claude -p \
  --dangerously-skip-permissions \
  --verbose \
  --output-format stream-json \
  --prompt-suggestions false \
  "$PROMPT" \
  2>"$STDERR_LOG" \
| tee "$RAW_LOG" \
| jq -Rr --unbuffered '
  fromjson?
  | select(.type=="assistant")
  | .message.content[]?
  | select(.type=="text")
  | .text
  | split("\n")[]
  | select(startswith("[[USER_MESSAGE]]"))
  | sub("^\\[\\[USER_MESSAGE\\]\\]"; "")
' \
| tee "$USER_LOG"
