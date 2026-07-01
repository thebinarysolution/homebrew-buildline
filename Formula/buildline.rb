# Homebrew formula for BuildLine. This is the file that lives in the PUBLIC tap
# repo (github.com/thebinarysolution/homebrew-buildline) at Formula/buildline.rb.
# The source stays private; this only points at the compiled release archive.
# Regenerate the url/sha256/version on each release (see docs/RELEASING.md).
class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.4.1"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.4.1/buildline_0.4.1_darwin_all.tar.gz"
  sha256 "741395df892801c67a42a5a9fd1808cc2a04b0ca9ced6705e55f0be18a9d1056"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
