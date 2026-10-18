# Bingo Send

**继续用豆包或你喜欢的输入法，说完 Bingo 就发送。**

Bingo Send 是一个独立的 macOS 菜单栏应用：等输入法把文字写进聊天框，在句尾检测到口令、文字稳定后，核验焦点和光标，再触发目标应用的发送按键。**正文与 Bingo 全部原样保留。**

> 输入 `帮我检查这个页面，Bingo。` → 自动发送完整的 `帮我检查这个页面，Bingo。`

[English](README.md) · **简体中文** · [GitHub 项目](https://github.com/yangyang2049/bingo-send) · [使用指南](docs/USER_GUIDE.zh-CN.md) · [兼容性记录](docs/COMPATIBILITY.zh-CN.md) · [隐私说明](docs/PRIVACY.zh-CN.md)

## 下载与安装

普通用户无需安装 Codex、Skill、Xcode 或命令行工具。应用界面目前为中文；项目文档提供中英文版本，后续可继续贡献界面本地化。

1. 下载 [1.1.1 通用安装包](https://github.com/yangyang2049/bingo-send/releases/download/v1.1.1/BingoSend-1.1.1-macOS-universal.dmg)，或到 [Releases](https://github.com/yangyang2049/bingo-send/releases/latest) 查看最新版本。`universal` 包含 Apple Silicon 与 Intel 两种架构；也可选择与你的 Mac 匹配的单架构包。
2. 打开 DMG，把 **Bingo Send.app** 拖到 **Applications / 应用程序**，然后从应用程序目录打开。
3. 点“去授权…”，在 macOS 系统设置中为 Bingo Send 开启**辅助功能**权限。
4. 启用目标应用，核对发送按键。Codex 的默认值为 **Return**；浏览器请配置允许的网站域名。
5. 先打开“启用口令发送”，用默认的“只检测，不发送”试一条新内容；听到提示后，关闭“只检测，不发送”，再试一次实际发送。

首次使用默认只检测；每次重新启动都从暂停状态开始。关闭设置窗口后应用仍在菜单栏；从菜单栏可以暂停或退出。

**签名与权限：** 当前安装包使用 ad-hoc 临时签名，未经 Apple 公证，首次打开可能被 Gatekeeper 拦截。请按 [Apple 的打开说明](https://support.apple.com/102445)处理；无需关闭系统安全机制。辅助功能权限始终需要用户亲自授予。维护者可按 [发布指南](docs/RELEASING.zh-CN.md)完成 Developer ID 签名和公证。

## 有哪些功能

- 句尾口令可自定义；默认 `Bingo`，忽略英文大小写，兼容末尾空白和标点。
- 等待文字稳定后发送，默认 1 秒，可调为 0.5～3 秒。
- 按应用启用，支持 `Return`、`⌘ Return`、`⌃ Return` 三种发送按键。
- 已识别浏览器强制限定网站域名，地址无法确认时不处理。其他浏览器需要手动打开“按网页域名限制”。
- 只检测当前聚焦的输入框，核验光标在末尾、未选中文字，避免切换焦点后继续发送。
- 不录音、不联网、不保存输入正文，也不修改文字、选区或剪贴板。

输入来源不限语音，手动输入或粘贴以口令结尾的新内容也会触发。工具不能结束输入法录音，只能在文字上屏后处理；连续转写时请留意等待时间。

## 能用于哪些应用

**1.1.0 已在 Codex 实测自动发送成功。** 1.1.1 沿用其核心发送逻辑，已通过构建、签名及打包验证。WorkBuddy、DeepSeek、Hugging Face 及其他应用或网站需要逐个验证；加入名单不代表兼容。

目标输入框必须公开 macOS 辅助功能文本和光标信息。部分自绘编辑器或网页编辑器不具备这些能力。详见 [兼容性记录与贡献方法](docs/COMPATIBILITY.zh-CN.md)。支持 macOS 13 及以上；最低系统版本和 Intel 运行兼容性仍需实际设备验证。

## 从源码构建

安装 Xcode 或 Xcode Command Line Tools，确保 Swift 5.9 及以上，然后在仓库目录执行：

```sh
swift test
./build.sh
```

输出为 `build/Bingo Send.app`。默认仅构建当前机器架构。

```sh
./build.sh --universal
./scripts/package-release.sh
```

通用构建包含 `arm64` 与 `x86_64`，打包输出位于 `dist/`，包含 DMG、ZIP 和 SHA-256 校验文件。默认使用临时签名；正式分发见 [发布指南](docs/RELEASING.zh-CN.md)。CI 执行单元测试和构建；手动发布工作流生成 **Draft Release**，由维护者检查后发布。

## 独立应用与 Skill

常驻检测输入框和发出系统按键由 macOS 应用承担。Skill 可以补充安装、配置或排错说明，但用户安装应用后无需运行 AI Agent，也无需安装 Skill。

## 参与与许可

欢迎提交兼容性反馈、问题和 Pull Request。请先看 [贡献指南](CONTRIBUTING.zh-CN.md)，勿在 Issue 中粘贴真实聊天、口令凭据或隐私数据。

采用 [MIT 许可证](LICENSE)。本项目为独立工具，与所提及的输入法和 AI 产品没有隶属关系。
