#!/usr/bin/env bash
set -o pipefail

# Fill these before running.
SCENE_ID="scene-001"
PROMPT="$(cat <<'PROMPT_EOF'
你是一个非交互式 coding agent。

任务：
1. 根据当前镜头文案和时长，设计 1080x1440、30fps、静音的 MG 动画。
2. 使用 hyperframes 编写并渲染 mp4。
3. 将动画设计写入 design.md。
4. 不要提问；直接写文件、渲染并交付 mp4。

镜头信息：
- 镜头编号：scene-001
- 时长：TODO 秒
- 文案：
TODO: 粘贴该镜头对应的字幕文本。

进度输出规则：
- 关键阶段完成时，单独输出一行 [[USER_MESSAGE]] 开头的消息。
- 至少输出这些阶段：
[[USER_MESSAGE]]设计已写入 design.md
[[USER_MESSAGE]]代码已完成，开始渲染
[[USER_MESSAGE]]视频已渲染完成：TODO.mp4
- 除上述关键消息外，不要输出其他用户可见进度文本。
PROMPT_EOF
)"

claude -p \
  --dangerously-skip-permissions \
  --verbose \
  --output-format stream-json \
  --prompt-suggestions false \
  "$PROMPT" \
  2>"claude-${SCENE_ID}.stderr.log" \
| jq -Rr --unbuffered '
  fromjson?
  | select(.type=="assistant")
  | .message.content[]?
  | select(.type=="text")
  | .text
  | split("\n")[]
  | select(startswith("[[USER_MESSAGE]]"))
  | sub("^\\[\\[USER_MESSAGE\\]\\]"; "")
'
