class Kwwk < Formula
  desc "Swift-native coding-agent CLI (Anthropic, Codex, Gemini, Copilot)"
  homepage "https://github.com/EYHN/kwwk"
  url "https://github.com/EYHN/kwwk/archive/refs/tags/v0.1.34.tar.gz"
  sha256 "3d776f73f1e3ac1fb6c718af76215c10c315fa37aed591d9b4a22936a0a873ff"
  license "MIT"
  head "https://github.com/EYHN/kwwk.git", branch: "main"

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
