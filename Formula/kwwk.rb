class Kwwk < Formula
  desc "Swift-native coding-agent CLI (Anthropic, Codex, Gemini, Copilot)"
  homepage "https://github.com/EYHN/kwwk"
  url "https://github.com/EYHN/kwwk/archive/refs/tags/v0.1.114.tar.gz"
  sha256 "c5d47b45e193e8bff6fb3f56aeaf2fbc453cc8ba2b03b9adddb37edb61fb0a98"
  license "MIT"
  head "https://github.com/EYHN/kwwk.git", branch: "main"

  bottle do
    root_url "https://github.com/EYHN/homebrew-tap/releases/download/kwwk-0.1.114"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "1e3f2224bb66163a7a73273e7f629cc7260acdf04270f5d20b3e0c141893093d"
    sha256 cellar: :any_skip_relocation, sequoia:       "9a8fca215c42f720913034e523bafb2997464822a2e191897ba652e51256f6bd"
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
