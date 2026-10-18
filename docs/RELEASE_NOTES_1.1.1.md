# Bingo Send 1.1.1

[English](RELEASE_NOTES_1.1.1.md) | [简体中文](RELEASE_NOTES_1.1.1.zh-CN.md)

Keep using Doubao or your preferred input method. End a new message with Bingo, and Bingo Send triggers sending after the text settles. The complete message, including Bingo, is preserved unchanged.

## Installation

Requires macOS 13 or later. Download `BingoSend-1.1.1-macOS-universal.dmg`, drag Bingo Send into Applications, and open it. The universal package contains Apple Silicon and Intel architectures; operation on Intel hardware and the minimum macOS version still needs device testing.

This package uses an ad hoc signature and has not been notarized by Apple. If Gatekeeper blocks it, follow Apple's guidance in System Settings. You must grant Accessibility permission yourself on first use. Verify detection-only mode before enabling actual sending. No Codex installation or Skill is required.

## Changes

- New installations use Return as the default send shortcut for Codex, matching the shortcut verified in testing. Existing saved settings are preserved.
- Added the MIT-licensed open-source project, English and Chinese documentation, a privacy statement, and a way to report compatibility results.
- Added universal builds, DMG and ZIP packages, SHA-256 checksums, automated builds, and a manual workflow for preparing draft releases.

## Verification and limitations

All 28 core tests passed. The arm64 and universal builds, ad hoc signature validation, ZIP extraction, and DMG mounting checks passed. Version 1.1.0 was tested successfully with a local WKWebView editor and the user's Codex app. Version 1.1.1 retains that core sending logic, corrects the default configuration for new users, and prepares the project for distribution. Other apps and websites need individual verification; their input fields must expose text and cursor information through Accessibility.

Bingo Send does not record audio, make network requests, or save chat text. It does not stop dictation in your input method. It starts paused after every relaunch.
