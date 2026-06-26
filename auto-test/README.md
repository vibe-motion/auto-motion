# Auto-test

这个测试用于验证最小闭环：

`codex exec < PROMPT.md` 非交互主控 -> 单个 Claude 子 agent -> hyperframes 渲染 -> ffprobe 自动验收。

运行：

```bash
bash auto-test/run.sh
```

测试会创建隔离目录 `auto-test/.tmp/run`，复制 `PROMPT.md`、`exampleFolder` 和 1 秒 `transcription.srt`，再用 `codex exec < PROMPT.md` 执行主控流程。它会真实调用 Codex 和 Claude，可能产生模型调用和 hyperframes/npm 下载耗时。

自动判定通过条件：

- `codex exec` 成功退出。
- `scenes/scene-001/design.md` 已被 Claude 改写，不再是模板占位内容。
- Claude 阶段日志 `claude-scene-001.user.log` 包含需求检查、设计、代码完成、自检、渲染完成五类进度消息。
- `scenes/scene-001/scene-001.mp4` 和 `final.mp4` 均存在。
- 视频为 1080x1440、30fps、时长约 1 秒、无音轨。

验收脚本只判断客观产物，不评价视觉美术效果。
