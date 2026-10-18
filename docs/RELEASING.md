# Building and Releasing

[English](RELEASING.md) | [简体中文](RELEASING.zh-CN.md)

This guide is for maintainers of [yangyang2049/bingo-send](https://github.com/yangyang2049/bingo-send). Build each release from its corresponding tag, and check the version, architectures, and release notes against the packaged app. Users can download builds from [Releases](https://github.com/yangyang2049/bingo-send/releases/latest).

## Release packages

```sh
swift test
./build.sh --universal
./scripts/package-release.sh
```

The output is written to `dist/`:

- `BingoSend-1.1.1-macOS-universal.dmg`
- `BingoSend-1.1.1-macOS-universal.zip`
- `SHA256SUMS.txt`

The default build targets the current machine's architecture. `--universal` builds `arm64-apple-macosx13.0` and `x86_64-apple-macosx13.0` separately and combines them with lipo. Including both architectures does not mean that operation on Intel hardware or the minimum macOS version has been verified on devices.

The packaging script also accepts `./scripts/package-release.sh --app "/path/to/Bingo Send.app"`. It reads the version and architectures from the app without rebuilding, re-signing, or launching it. Packages from older versions or other architectures may coexist in `dist/`; select only the files for the release being published.

## Signing and notarization

The default build uses an ad hoc signature for development verification. It is not signed with an Apple Developer ID certificate or notarized by Apple. GitHub workflows also use ad hoc signing; release notes must state this accurately.

For public distribution, use a Developer ID Application certificate from the maintainer's own Apple Developer Program account. [Apple's documentation](https://developer.apple.com/developer-id/) explains signing, notarization, and their requirements. This project contains no certificates, account credentials, or notarization credentials.

Once the certificate is available in the local keychain, run:

```sh
BINGO_SIGN_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' ./build.sh --universal
```

This enables the hardened runtime and a secure timestamp; notarization is still required. After configuring a notarytool keychain profile named `bingo-notary`, run:

```sh
ditto -c -k --sequesterRsrc --keepParent 'build/Bingo Send.app' build/BingoSend-notarization.zip
xcrun notarytool submit build/BingoSend-notarization.zip --keychain-profile bingo-notary --wait
xcrun stapler staple 'build/Bingo Send.app'
xcrun stapler validate 'build/Bingo Send.app'
spctl --assess --type execute --verbose=2 'build/Bingo Send.app'
./scripts/package-release.sh
```

Staple only after notarization succeeds, then repackage the app and regenerate the checksums. Publish packages containing the stapled app. If signing or notarizing the DMG itself, do so after creating the final DMG and regenerate its checksum afterward. Current CI does not import certificates, notarize builds, or use your Apple credentials.

Users must grant Accessibility permission themselves; see [Apple's permission guide](https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185/mac). Rebuilding an app with an ad hoc signature may require granting permission again. A stable Developer ID helps preserve the app's identity, but upgrades still need testing.

## First upload to GitHub

Before uploading, confirm the MIT license, project name, public visibility, and all file contents. GitHub CLI must be authenticated with permission to create the repository and push code. Do not put tokens in scripts or the repository.

From the project root:

```sh
gh auth login --web --git-protocol https
git init -b main
git add .
git diff --cached --stat
git commit -m "Initial open-source release"
gh repo create bingo-send --public --source . --remote origin --push
```

Check `git status` before committing. Do not commit `.build/`, `build/`, `dist/`, certificates, or local credentials. If a Git repository or `origin` already exists, use its existing configuration; do not initialize it again or overwrite its remote.

## GitHub Actions

`CI` runs `swift test` and builds a package for the runner's architecture on pushes, pull requests, and manual dispatches.

`Prepare draft release` supports manual dispatch only. First update the public version and internal build number in Info.plist, the changelog, and compatibility records. Commit the changes, then create and push the corresponding tag:

```sh
git tag -a v1.1.1 -m "Bingo Send 1.1.1"
git push origin v1.1.1
```

Once the workflow is present on the default branch, open Actions → Prepare draft release → Run workflow and enter the version without `v`, such as `1.1.1`. The workflow checks out an existing tag, requires its Info.plist version to match, runs tests, builds a universal app, packages it, uploads an Actions artifact, and creates a **draft release**. It does not publish the release automatically.

The workflow uploads ad hoc signed, unnotarized packages. To publish locally built packages signed with Developer ID and notarized, follow the local steps above, upload those files to the draft release, replace the ad hoc signed attachments with the same names, and update the notes and checksums. Do not mix the two sets of artifacts.

## Before publishing

- Drag the app from the final DMG into a separate test directory and verify its signature, version, and both architectures. Avoid replacing the only copy currently in use.
- On supported devices, verify permission setup, detection-only mode, an actual send, preservation of the complete draft, pause behavior, and restart behavior.
- Verify release attachments with `shasum -a 256 -c SHA256SUMS.txt`, and check that the version matches the tag.
- State the signing and notarization status, verified environments, installation steps, and known limitations in the release notes.
- Check that README download links, changelog dates, compatibility records, and release status match the artifacts. Publish the draft after confirming that its attachments are downloadable.

GitHub [Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases) can include DMG, ZIP, and checksum attachments, so users do not need to compile the app themselves.
