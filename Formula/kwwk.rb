class Kwwk < Formula
  desc "Swift-native coding-agent CLI (Anthropic, Codex, Gemini, Copilot)"
  homepage "https://github.com/EYHN/kwwk"
  url "https://github.com/EYHN/kwwk/archive/refs/tags/v0.1.32.tar.gz"
  sha256 "dce56d41efa27c01aeb02d2702894de264f34fa887f85237a97396d5664659c5"
  license "MIT"
  head "https://github.com/EYHN/kwwk.git", branch: "main"

  bottle do
    root_url "https://github.com/EYHN/homebrew-tap/releases/download/kwwk-0.1.32"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "0d6629864a6c6fb7c6eca6886c424d30e5ffb953d88dec37141abd9527d8489a"
    sha256 cellar: :any_skip_relocation, sequoia:       "4985a7cf8e836deae59185bf220d7b4cdb4b2251a00df3ed3800a451faf11dc1"
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
