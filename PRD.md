transcription.srt 是一个字幕文件，你需要指挥claude AI用hyperframes生成每个分镜的MG动画视频。

你需要先根据 srt 粗略的分一下镜头，就是将单个文案或者连续的多个文案组合成一个镜头，衡量标准是文案内容是否在说一个东西，是否可以合并。你不要去设计镜头里面的MG动画，claude AI去做这个事并且写代码渲染为视频交还给你。

每个 claude AI 需要单独创建一个文件夹环境，参考 exampleFolder。文件夹内包含 `.claude` 文件夹（里面的 skills 指导动画制作）、`design.md`（让 AI 填写）和一个 `example.sh` 脚本。

不要手写超长 `claude -p ... "<prompt>"` 命令。流程改为：

1. 复制 exampleFolder 作为该镜头的工作目录。
2. 修改该目录里的 `example.sh`：填写镜头编号、镜头时长、字幕文案和期望 mp4 文件名。
3. 在该镜头目录执行 `./example.sh`。
4. 只监听脚本输出的关键阶段消息；脚本会过滤 `stream-json` 里的工具调用、思考、诊断等噪音。

`example.sh` 内部负责执行 claude：

```bash
claude -p --dangerously-skip-permissions --verbose --output-format stream-json --prompt-suggestions false "$PROMPT"
```

脚本只输出 AI 回复中以 `[[USER_MESSAGE]]` 开头的关键消息。提示词必须要求 AI 在重大阶段输出关键消息，例如：设计已写入、代码已完成开始渲染、视频已渲染完成。长时间没有关键输出时，不要立刻判死；先检查日志、文件产物、渲染进程和最终状态。但如果长时间没有任何文件变化或进程活动，需要中断并重跑。

你需要在脚本 prompt 里告诉 AI：他负责哪个镜头、包含哪几句文案、镜头时长（这些文案的时长之和）；让他根据文案设计动画，并把动画内容写进 design.md；告诉他用 hyperframes 自行设计（可以借鉴 GSAP 等动效库）和渲染。视频静音，不需要包含文案内容，规格统一为 1080x1440、30fps。让 AI 在给到 mp4 前不要问问题，非必要不解释，直接写文件和渲染。

只能同时invoke 一个claude AI，因此建议顺序执行。

当所有视频都做好后，你用ffmpeg拼接为一个大视频返回给我，任务结束。
