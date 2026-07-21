class Kwwk < Formula
  desc "Swift-native coding-agent CLI (Anthropic, Codex, Gemini, Copilot)"
  homepage "https://github.com/EYHN/kwwk"
  url "https://github.com/EYHN/kwwk/archive/refs/tags/v0.1.31.tar.gz"
  sha256 "a5b1534c61667c32df9d6b76137ff682a4bba207fd1b1bd3ff01c47c3d7b6579"
  license "MIT"
  head "https://github.com/EYHN/kwwk.git", branch: "main"

  bottle do
    root_url "https://github.com/EYHN/homebrew-tap/releases/download/kwwk-0.1.31"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "157c7c3d24559510502a92637f2df4282c1ce87ddd00c1e95295d7e2b85a1a64"
    sha256 cellar: :any_skip_relocation, sequoia:       "496ebea2e009e25a04642f13c7e9d6f8b862420dee0606c3f60d897b05af17ee"
  end

  depends_on xcode: ["16.0", :build]
  depends_on macos: :sonoma

  def install
    swift_output = Utils.safe_popen_read("swift", "--version")
    swift_version = swift_output[/Swift version (\d+(?:\.\d+)+)/, 1]
    if swift_version.nil? || Version.new(swift_version) < Version.new("6.1")
      odie "kwwk requires Swift 6.1 or newer to build from source"
    end

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
    help = shell_output("#{bin}/kwwk --help")
    assert_match "kwwk", help
    assert_path_exists libexec/"kwwk_KWWKAI.bundle/models.json"
    assert_path_exists libexec/"kwwk_KWWKAI.bundle/cursor-models.json"
    # v0.1.27 predates the offline resource self-test. Every later release
    # must keep the command working; do not silently infer support from --help.
    if build.head? || version > Version.new("0.1.27")
      assert_equal "resources: ok", shell_output("#{bin}/kwwk --self-test").strip
    end
  end
end
