class Kwwk < Formula
  desc "Swift-native coding-agent CLI (Anthropic, Codex, Gemini, Copilot)"
  homepage "https://github.com/EYHN/kwwk"
  url "https://github.com/EYHN/kwwk/archive/refs/tags/v0.1.26.tar.gz"
  sha256 "faea1a5eaf8111814c001509a9eec7a79f6e70b0bef8d98d41d38b29b097a297"
  license "MIT"
  head "https://github.com/EYHN/kwwk.git", branch: "main"

  depends_on :macos
  depends_on macos: :sonoma
  depends_on xcode: ["16.0", :build]

  def install
    system "swift", "build",
           "--disable-sandbox",
           "--configuration", "release",
           "--product", "kwwk"
    # The binary and its SwiftPM resource bundle must live side-by-side —
    # `Bundle.module` resolves `kwwk_KWWKAI.bundle` via `_NSGetExecutablePath`,
    # which returns the path passed to exec without following symlinks.
    # A symlink in `bin/` would therefore make `Bundle.module` look inside
    # `/opt/homebrew/bin/`. Use a shell shim that `exec`s the libexec path
    # directly so the child process sees libexec as its bundle directory.
    libexec.install ".build/release/kwwk"
    libexec.install ".build/release/kwwk_KWWKAI.bundle"
    (bin/"kwwk").write <<~SH
      #!/bin/bash
      exec "#{libexec}/kwwk" "$@"
    SH
    (bin/"kwwk").chmod 0755
  end

  test do
    assert_match "kwwk", shell_output("#{bin}/kwwk --help")
  end
end
