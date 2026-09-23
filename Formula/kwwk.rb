class Kwwk < Formula
  desc "Swift-native coding-agent CLI (Anthropic, Codex, Gemini, Copilot)"
  homepage "https://github.com/EYHN/kwwk"
  url "https://github.com/EYHN/kwwk/archive/refs/tags/v0.1.67.tar.gz"
  sha256 "a1093905bae7f388e9ac725b3eb3b77404d7aa7ed902e8c143c83a17548ded44"
  license "MIT"
  head "https://github.com/EYHN/kwwk.git", branch: "main"

  bottle do
    root_url "https://github.com/EYHN/homebrew-tap/releases/download/kwwk-0.1.67"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "6aa75e3c95f33f6b1dd64cdd7cc9bf833c72a42145883563c00303d6c95b00ac"
    sha256 cellar: :any_skip_relocation, sequoia:       "ea2325fd459ccc47800ab5c4ff2b5d803ecb33bf97950bc740a69787050238e1"
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
