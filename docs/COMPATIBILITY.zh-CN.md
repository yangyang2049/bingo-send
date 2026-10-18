[English](COMPATIBILITY.md) | 简体中文

# 兼容性记录

记录日期：2026-10-19。项目最低目标为 macOS 13；在某个版本成功不代表所有系统版本、同名产品或输入框均兼容。

| 环境 | 结果 | 已验证内容 |
| --- | --- | --- |
| Codex 桌面版，`com.openai.codex`，Apple Silicon | 用户实测通过 | 1.1.0，豆包输入，新文本句尾 Bingo，Return，正文和口令原样自动发送 |
| 独立本地 WKWebView 测试编辑器，Apple Silicon | 通过 | 1.1.0，两条完整正文（含中文、emoji、英文与口令）自动提交 |
| 1.1.1 | 28 测试、native/universal 构建、签名及打包验证通过 | 两种架构的最低目标均为 13.0；ZIP 解包及 DMG 挂载后 app 与构建一致；新安装 Codex 默认 Return；发送实现沿用 1.1.0 |
| WorkBuddy | 未验证 | 需要分别验证应用标识、AX 文本和光标、发送键 |
| DeepSeek 网页版 | 未验证 | `chat.deepseek.com` 仅为配置示例 |
| Hugging Face 网页版 | 未验证 | `huggingface.co` 仅为配置示例 |
| Safari、Chrome、Edge 及其他浏览器 | 未验证实际发送 | 内置浏览器标识不等于所有网页编辑器兼容 |
| Intel Mac、macOS 13 最低系统版本 | 待设备验证 | 包含 x86_64 二进制不等于已做 Intel 实机回归 |

## 验证一个新应用

1. 在设置中添加并启用目标 `.app`，核对 Return / Command-Return / Control-Return。
2. 浏览器需配置域名；未被识别的浏览器请手动打开“按网页域名限制”。
3. 启用总开关，先用“只检测，不发送”验证一条新输入。光标留在末尾，无文字选择。
4. 关闭只检测，再用无隐私的新测试句确认实际发送，核对收到的完整正文及 Bingo。
5. 在 Issue 中报告 macOS、芯片、Bingo Send 和目标应用版本、发送键及固定状态提示，说明语音输入法和是否持续上屏。无需提供真实聊天。

程序要求可读取的 `AXValue` 和 `AXSelectedTextRange`。新进入输入框时已有的草稿只作基线，不会立即发送。不能读出控件、光标或受限制页面地址时，程序停止处理该输入框，不做猜测。
