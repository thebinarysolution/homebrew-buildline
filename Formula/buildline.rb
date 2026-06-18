# Homebrew formula for BuildLine. This is the file that lives in the PUBLIC tap
# repo (github.com/thebinarysolution/homebrew-buildline) at Formula/buildline.rb.
# The source stays private; this only points at the compiled release archive.
# Regenerate the url/sha256/version on each release (see docs/RELEASING.md).
class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.3.0"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.3.0/buildline_0.3.0_darwin_all.tar.gz"
  sha256 "20d41a0bd96f0260837ae32d28ec358dca4bda9ea1dd5d44d28e4939f537bd10"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
