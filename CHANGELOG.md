# Changelog / 更新记录

## English

### 1.1.1 — 2026-10-19

- Use the verified Return shortcut for new Codex profiles; preserve existing saved settings.
- Add the MIT license, English and Simplified Chinese project documentation, privacy information, and compatibility records.
- Add universal builds, DMG/ZIP packaging, checksums, and GitHub Actions workflows.
- Packages are ad-hoc signed and are not Apple notarized.

### 1.1.0 — 2026-10-19

- Send the full unchanged draft after detecting a final keyword, keeping Bingo and leaving text and selections untouched.
- Validate focus, full text, caret, and page context before sending; add fixed status messages.
- Pass 28 core automated tests and actual send tests in a local WKWebView editor and a user's Codex app.

## 简体中文

### 1.1.1 — 2026-10-19

- 新安装的 Codex 配置默认使用已实测成功的 Return；已有用户保存的配置保持原样。
- 补充 MIT 许可证、中英文项目说明、隐私与兼容性文档。
- 增加通用架构构建、DMG/ZIP 打包、校验文件及 GitHub Actions 工作流。
- 安装包使用 ad-hoc 临时签名，未经 Apple 公证。

### 1.1.0 — 2026-10-19

- 检测句尾口令后原样发送完整正文，保留 Bingo，不改写文字或选区。
- 增加发送前的焦点、全文、光标、网页上下文核验和固定错误提示。
- 核心 28 个自动化测试通过；本地 WKWebView 及用户 Codex 实测自动发送成功。
