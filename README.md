# EYHN/homebrew-tap

Homebrew formulas for [EYHN](https://github.com/EYHN)'s tools.

## Install

```sh
brew install EYHN/tap/<formula>
```

## Formulas

### [`kwwk`](Formula/kwwk.rb) — Swift-native coding-agent CLI

```sh
brew install EYHN/tap/kwwk
```

Interactive TUI coding agent backed by your Anthropic, ChatGPT (Codex),
Gemini, or GitHub Copilot subscription. Source:
[EYHN/kwwk](https://github.com/EYHN/kwwk).

The executable supports macOS 14+. Release bottles target macOS 15+ on Apple
Silicon and Intel without a Swift or Xcode runtime dependency. A source build
needs a full Xcode 16+ installation plus a Swift 6.1-or-newer toolchain; on
macOS 15.2+ that toolchain is included with Xcode 16.3+.

## Publishing a kwwk release

Pushing a version tag in `EYHN/kwwk` creates the source release and opens a
formula bump pull request here. Wait for both `brew test-bot` builders to pass,
then run the `brew pr-pull` workflow with the pull request number and its exact
head SHA. That workflow publishes the bottle artifacts and pushes the formula
plus bottle checksums to `main`.
