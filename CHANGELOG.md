# Changelog / 更新记录

## English

### 1.2.0 — 2026-10-19

- Add 13 opt-in setup presets for common AI apps and websites, with search and region filters. Installed native apps can be selected directly; web presets let you choose an installed browser and merge allowed domains without replacing existing ones.
- Add a menu for choosing one active keyword: Bingo, Submit, Send, 发送, 提交, 完成, 确认, 确定, or a custom keyword.
- Add an optional **Remove final keyword before sending** toggle, off by default for both new and existing preferences. Keep mode preserves the entire draft; removal mode deletes only the matched suffix and its following punctuation or whitespace, then verifies the result before sending.
- Start fresh installations with every app disabled, detection-only mode on, and sending paused. Existing saved preferences are preserved; every launch still starts paused.
- Update the app icon to a black rounded square with a white paper plane.
- Fix app icon generation on Retina displays by rendering into an `NSBitmapImageRep` with explicit physical pixel dimensions instead of using `NSImage.lockFocus()`.
- Validate the names and pixel dimensions of all 10 standard icon PNG variants, then validate them again after an ICNS round trip during the build.
- Refuse release app packaging when local-only test tooling is included.
- Document how to restore Accessibility permission when an old ad-hoc signature leaves a stale system entry.
- Keep mode remains the default. Presets are setup suggestions, not compatibility certifications, and removal needs separate editor verification. Packages remain ad-hoc signed and are not Apple notarized; the app interface remains Chinese.

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

### 1.2.0 — 2026-10-19

- 增加 13 个需主动添加的常用 AI 应用和网站配置预设，支持搜索和国内/国外筛选；已安装的原生应用可直接选择，网页预设可选择已安装浏览器并合并域名，保留原有范围。
- 增加常用口令选择菜单：Bingo、Submit、Send、发送、提交、完成、确认、确定，也可自定义；每次只启用一个口令。
- 增加可选的“发送前移除句尾口令”，全新和已有配置默认均关闭。保留模式发送完整草稿；移除模式仅删除匹配的句尾口令及其后的标点和空白，读回核验后再发送。
- 全新安装的应用列表默认全部关闭，默认只检测、发送暂停；已有保存配置不迁移、不覆盖，每次启动仍从暂停开始。
- 应用图标改为黑色圆角方形底、白色纸飞机。
- 修复 Retina 屏幕下的应用图标生成：使用指定物理像素尺寸的 `NSBitmapImageRep` 绘制，替代 `NSImage.lockFocus()`。
- 构建时校验全部 10 个标准图标 PNG 的文件名和像素尺寸，并在 ICNS 转回 iconset 后再次校验。
- 发布应用包中若包含仅限本地的测试工具，打包流程会拒绝继续。
- 补充旧 ad-hoc 签名导致系统授权条目失效时的辅助功能权限恢复方法。
- 默认仍为保留模式。预设只帮助配置，不代表已验证兼容，移除模式也需单独验证编辑器支持。安装包仍为 ad-hoc 临时签名，未经 Apple 公证；应用界面仍为中文。

### 1.1.1 — 2026-10-19

- 新安装的 Codex 配置默认使用已实测成功的 Return；已有用户保存的配置保持原样。
- 补充 MIT 许可证、中英文项目说明、隐私与兼容性文档。
- 增加通用架构构建、DMG/ZIP 打包、校验文件及 GitHub Actions 工作流。
- 安装包使用 ad-hoc 临时签名，未经 Apple 公证。

### 1.1.0 — 2026-10-19

- 检测句尾口令后原样发送完整正文，保留 Bingo，不改写文字或选区。
- 增加发送前的焦点、全文、光标、网页上下文核验和固定错误提示。
- 核心 28 个自动化测试通过；本地 WKWebView 及用户 Codex 实测自动发送成功。
