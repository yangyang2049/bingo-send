# Changelog / 更新记录

## English
+
+### 1.3.2 — preview, 2026-10-30
+
+- Request native Accessibility access once on first main-window presentation when untrusted; avoid opening a competing settings window.
+- Collapse authorized permissions into diagnostics; restore primary guidance if access is lost.
+- Explain the target-app opt-in step and link directly to it before choosing a run mode.
+- Add isolated first-launch, rejection, regrant/revocation, and preferences-reset regressions. Actual installation and local fixture QA are recorded separately.
+
+
### 1.3.1 — preview, 2026-10-30

- Replace overlapping enable/detect-only switches with Paused / Test detection / Auto send in Settings and the menu bar.
- Show the effective mode or permission/keyword/app block in the header and menu icon. Pause remains selectable when settings are invalid.
- Disable the removal control during detection tests and explain that tests never edit or send.
- Make the local preview respect detection mode and discard stale results after sample or configuration changes.
- Preserve saved preferences and start paused after every launch. Add isolated mode/relaunch regression tests without touching real user settings.
- Keep the existing verified-edit and focus checks; a posted shortcut is not proof of message delivery.

### 1.3.0 — unreleased

- Support up to 3 final keywords at once; any one of them at the end of the draft sends. Matching is unchanged otherwise: suffix only, case-insensitive, trailing punctuation and whitespace allowed.
- Fresh installations are prefilled with 3 keywords in the interface language: Bingo, Submit, Send for English, and 发送, 提交, 完成 for Simplified Chinese. Other languages follow the English set.
- Add **Fill in common keywords** quick sets for English three, Chinese three, and mixed Bingo / Send / 发送, plus per-row editing so users can mix languages or write their own.
- Match the longest keyword when several fit the suffix, so a keyword pair such as Bingo Send is never trimmed to Send.
- Removal mode deletes only the keyword that matched this draft instead of the previously configured single keyword.
- Saved 1.2.0 preferences keep their one keyword and are not expanded into extra triggers. The legacy `keyword` field is still written for older builds.

### 1.2.0 — 2026-10-19

- Add 13 opt-in setup presets for common AI apps and websites, in one searchable list. Installed native apps can be selected directly; web presets let you choose an installed browser and merge allowed domains without replacing existing ones.
- Follow the system’s preferred language with English or Simplified Chinese UI; use English for other languages.
- Add a menu for choosing one active keyword: Bingo, Submit, Send, 发送, 提交, 完成, 确认, 确定, or a custom keyword.
- Add an optional **Remove final keyword before sending** toggle, off by default for both new and existing preferences. Keep mode preserves the entire draft; removal mode deletes only the matched suffix and its following punctuation or whitespace, then verifies the result before sending.
- Start fresh installations with every app disabled, detection-only mode on, and sending paused. Existing saved preferences are preserved; every launch still starts paused.
- Update the app icon to a black rounded square with a white paper plane.
- Fix app icon generation on Retina displays by rendering into an `NSBitmapImageRep` with explicit physical pixel dimensions instead of using `NSImage.lockFocus()`.
- Validate the names and pixel dimensions of all 10 standard icon PNG variants, then validate them again after an ICNS round trip during the build.
- Refuse release app packaging when local-only test tooling is included.
- Document how to restore Accessibility permission when an old ad-hoc signature leaves a stale system entry.
- Keep mode remains the default. Presets are setup suggestions, not compatibility certifications, and removal needs separate editor verification. Packages remain ad-hoc signed and are not Apple notarized.

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
+
+### 1.3.2 — 预览版，2026-10-30
+
+- 首次打开主窗口且未授权时自动发起一次原生授权请求，不再同时跳出第二套设置界面。
+- 已授权入口移入折叠的「权限与诊断」，失效时重新显示顶部引导。
+- 明确授权后仍需选择目标应用，提供直接定位入口，再由用户选择运行模式。
+- 补充隔离的首次、拒绝、重新授权／撤权、清偏好回归；实际安装及本地输入夹具验证另行记录。
+
+
### 1.3.1 — 预览版，2026-10-30

- 设置与菜单栏统一使用「暂停／测试识别／自动发送」，替换两个含义重叠的开关。
- 顶栏与菜单图标显示真实模式或权限、口令、应用范围受阻原因；配置无效时仍可随时暂停。
- 测试识别时禁用移除设置，明确只提示音、不修改、不发送。
- 本地口令预览遵循测试模式；修改示例、口令、模式或移除选项后，旧结果自动失效。
- 保留已有配置，每次启动仍暂停；增加隔离的模式和重启回归测试，不碰真实偏好。
- 保留原有焦点及修改核验；发出发送按键仍不代表目标应用已收到消息。

### 1.3.0 — 未发布

- 支持最多 3 个句尾口令同时生效，句中任意一个出现在末尾即发送；其余匹配规则不变：只认句尾、忽略大小写、兼容尾随标点与空白。
- 全新安装按界面语言预填 3 个口令：英文为 Bingo、Submit、Send，简体中文为 发送、提交、完成；其他语言同英文。
- 增加「填入常用口令」快捷组：英文三个、中文三个、中英混用（Bingo、Send、发送）；每一行也可自由改写，方便中英混用和自定义。
- 多个口令都能匹配句尾时以较长者为准，因此 Bingo Send 不会被截成 Send。
- 移除模式只删除本次实际命中的那个口令，而不是旧版配置里唯一的口令。
- 已保存的 1.2.0 配置保留原有单个口令，不会自动变出更多触发词；旧字段 `keyword` 仍会写出，供旧版本读取。

### 1.2.0 — 2026-10-19

- 增加 13 个需主动添加的常用 AI 应用和网站配置预设，统一列出并支持搜索；已安装的原生应用可直接选择，网页预设可选择已安装浏览器并合并域名，保留原有范围。
- 界面按系统首选语言自动使用英文或简体中文，其他语言回退英文。
- 增加常用口令选择菜单：Bingo、Submit、Send、发送、提交、完成、确认、确定，也可自定义；每次只启用一个口令。
- 增加可选的“发送前移除句尾口令”，全新和已有配置默认均关闭。保留模式发送完整草稿；移除模式仅删除匹配的句尾口令及其后的标点和空白，读回核验后再发送。
- 全新安装的应用列表默认全部关闭，默认只检测、发送暂停；已有保存配置不迁移、不覆盖，每次启动仍从暂停开始。
- 应用图标改为黑色圆角方形底、白色纸飞机。
- 修复 Retina 屏幕下的应用图标生成：使用指定物理像素尺寸的 `NSBitmapImageRep` 绘制，替代 `NSImage.lockFocus()`。
- 构建时校验全部 10 个标准图标 PNG 的文件名和像素尺寸，并在 ICNS 转回 iconset 后再次校验。
- 发布应用包中若包含仅限本地的测试工具，打包流程会拒绝继续。
- 补充旧 ad-hoc 签名导致系统授权条目失效时的辅助功能权限恢复方法。
- 默认仍为保留模式。预设只帮助配置，不代表已验证兼容，移除模式也需单独验证编辑器支持。安装包仍为 ad-hoc 临时签名，未经 Apple 公证。

### 1.1.1 — 2026-10-19

- 新安装的 Codex 配置默认使用已实测成功的 Return；已有用户保存的配置保持原样。
- 补充 MIT 许可证、中英文项目说明、隐私与兼容性文档。
- 增加通用架构构建、DMG/ZIP 打包、校验文件及 GitHub Actions 工作流。
- 安装包使用 ad-hoc 临时签名，未经 Apple 公证。

### 1.1.0 — 2026-10-19

- 检测句尾口令后原样发送完整正文，保留 Bingo，不改写文字或选区。
- 增加发送前的焦点、全文、光标、网页上下文核验和固定错误提示。
- 核心 28 个自动化测试通过；本地 WKWebView 及用户 Codex 实测自动发送成功。
