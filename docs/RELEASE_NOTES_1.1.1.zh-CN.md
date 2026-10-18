# Bingo Send 1.1.1

[English](RELEASE_NOTES_1.1.1.md) | [简体中文](RELEASE_NOTES_1.1.1.zh-CN.md)

继续用豆包或其他输入法，把一条新消息以 Bingo 结尾，文字稳定后自动触发发送。完整正文和 Bingo 原样保留。

## 安装

macOS 13 及以上。下载 `BingoSend-1.1.1-macOS-universal.dmg`，把 Bingo Send 拖入“应用程序”并打开。通用包包含 Apple Silicon 和 Intel 架构；Intel 和最低 macOS 版本尚待实机验证。

当前包使用 ad-hoc 临时签名，未经 Apple 公证。若 Gatekeeper 阻止打开，请按 Apple 的系统设置指引处理。首次使用需亲自授予辅助功能权限，先在只检测模式验证，再启用实际发送。无需安装 Codex 或 Skill。

## 变化

- Codex 新安装的默认发送键改为已实测成功的 Return，已有保存配置保持原样。
- 提供 MIT 开源项目、中英文说明、隐私说明和兼容性反馈入口。
- 提供通用构建、DMG / ZIP 和 SHA-256 校验，以及自动构建与手动草稿发布工作流。

## 验证与限制

28 个核心测试通过，arm64 与 universal 构建、临时签名校验、ZIP 解包及 DMG 挂载校验通过。1.1.0 曾在本地 WKWebView 编辑器和用户 Codex 中实测自动发送；1.1.1 沿用其核心发送逻辑，修正新用户默认配置并整理发布。其他应用或网站需分别验证，输入框必须公开辅助功能文本和光标信息。

本工具不录音、不联网、不保存聊天正文，不会替输入法结束录音。每次重启默认暂停。
