class Kwwk < Formula
  desc "Swift-native coding-agent CLI (Anthropic, Codex, Gemini, Copilot)"
  homepage "https://github.com/EYHN/kwwk"
  url "https://github.com/EYHN/kwwk/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "d48ee6a3caa184f176c1a55fefb1f7da1a59d1172fa58cf42767fae02530cc3a"
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
    bin.install ".build/release/kwwk"
  end

  test do
    assert_match "kwwk", shell_output("#{bin}/kwwk --help")
  end
end
