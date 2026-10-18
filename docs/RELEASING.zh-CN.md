# 构建与发布

[English](RELEASING.md) | [简体中文](RELEASING.zh-CN.md)

本文供 [yangyang2049/bingo-send](https://github.com/yangyang2049/bingo-send) 的维护者构建和发布新版本使用。每次发布都应从对应 tag 构建，并核对安装包中的版本、架构与发布说明。下载入口为 [Releases](https://github.com/yangyang2049/bingo-send/releases/latest)。

## 安装包

```sh
swift test
./build.sh --universal
./scripts/package-release.sh
```

输出位于 `dist/`：

- `BingoSend-1.1.1-macOS-universal.dmg`
- `BingoSend-1.1.1-macOS-universal.zip`
- `SHA256SUMS.txt`

默认构建为当前机器架构；`--universal` 分别构建 `arm64-apple-macosx13.0` 和 `x86_64-apple-macosx13.0` 后用 lipo 合并。两种二进制并不代表最低系统版本和 Intel 运行行为都已做设备验证。

打包脚本也接受 `./scripts/package-release.sh --app "/path/to/Bingo Send.app"`。它从 app 自身读取版本和架构，不重编译、不改签、不启动应用。不同架构或旧版本包可能共存于 dist，提交发布前只选择本次版本文件。

## 签名和公证

默认是 ad-hoc 临时签名，适合开发验证，不代表 Apple 开发者签名或公证。GitHub 工作流也使用这种签名，发布说明必须如实标注。

正式分发建议使用维护者自己 Apple Developer Program 账号的 Developer ID Application 证书；[Apple 说明](https://developer.apple.com/developer-id/)介绍签名、公证及要求。本项目不包含证书、账号或公证凭据。

证书已在本机钥匙串准备好后，可运行：

```sh
BINGO_SIGN_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' ./build.sh --universal
```

此方式启用 hardened runtime 和安全时间戳，随后仍需公证。维护者可事先配置名为 `bingo-notary` 的 notarytool 钥匙串配置，再执行：

```sh
ditto -c -k --sequesterRsrc --keepParent 'build/Bingo Send.app' build/BingoSend-notarization.zip
xcrun notarytool submit build/BingoSend-notarization.zip --keychain-profile bingo-notary --wait
xcrun stapler staple 'build/Bingo Send.app'
xcrun stapler validate 'build/Bingo Send.app'
spctl --assess --type execute --verbose=2 'build/Bingo Send.app'
./scripts/package-release.sh
```

只有公证通过后才执行 staple，并重新打包、更新校验文件。发布的是 stapled app 的安装包；如还要对 DMG 自身签名或公证，请在最终 DMG 完成后处理，并重新生成校验文件。当前 CI 不导入证书、不公证、不使用你的 Apple 凭据。

辅助功能授权必须由用户亲自完成；[Apple 权限说明](https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185/mac)。临时签名重新构建后可能需要重新授权，使用稳定的 Developer ID 有助于维持应用身份，但仍应做升级验证。

## 第一次上传 GitHub

确认 MIT 许可证、项目名称、公开范围与所有文件内容后再操作。GitHub CLI 需要已登录且有创建仓库和推送代码的权限；不要把 token 放进脚本或仓库。

在本项目根目录中：

```sh
gh auth login --web --git-protocol https
git init -b main
git add .
git diff --cached --stat
git commit -m "Initial open-source release"
gh repo create bingo-send --public --source . --remote origin --push
```

提交前检查 `git status`，`.build/`、`build/`、`dist/`、证书和本机凭据不能进入源码提交。若目录已有 Git 仓库或 origin，请使用现有配置，不要重复初始化或覆盖远端。

## GitHub Actions

`CI` 在 push、Pull Request 和手动触发时执行 `swift test` 与本机架构打包构建。

`Prepare draft release` 只支持手动触发。先更新 Info.plist 的公开版本和内部构建号、CHANGELOG、兼容性记录，提交后创建并推送对应 tag：

```sh
git tag -a v1.1.1 -m "Bingo Send 1.1.1"
git push origin v1.1.1
```

在默认分支已包含工作流的前提下，打开 Actions → Prepare draft release → Run workflow，输入不带 v 的版本号（如 `1.1.1`）。它只 checkout 已存在的 tag，要求 Info.plist 版本一致，测试、通用构建、打包后上传 Actions Artifact，并创建 **Draft Release**。工作流不自动公开发布。

工作流上传的是 ad-hoc 未公证包。如需发布本机 Developer ID 签名且已公证的包，先按前述本机步骤生成，再通过 Release 草稿页面上传对应文件，替换同名临时签名附件，更新说明和校验文件；不要混用两套产物。

## 发布前检查

- 从最终 DMG 拖到独立测试目录，核验 app 签名、版本及两个架构。不要直接替换唯一正在使用的版本。
- 在支持的设备上验证授权、只检测、一次实际发送、正文原样保留、暂停和重启。
- 用 `shasum -a 256 -c SHA256SUMS.txt` 验证发布附件，确保版本与 tag 对应。
- Release 说明写明签名/公证状态、已验证环境、安装方法与已知限制。
- 核对 README 下载链接、CHANGELOG 日期、兼容性记录及 Release 状态与本次产物一致；确认附件可下载后再将草稿发布。

发布页基于 GitHub [Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)，可附带 DMG、ZIP 和校验文件，普通用户无需自己编译。
