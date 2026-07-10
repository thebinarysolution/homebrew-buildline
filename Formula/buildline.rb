# Homebrew formula for BuildLine. This is the file that lives in the PUBLIC tap
# repo (github.com/thebinarysolution/homebrew-buildline) at Formula/buildline.rb.
# The source stays private; this only points at the compiled release archive.
# Regenerate the url/sha256/version on each release (see docs/RELEASING.md).
class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.4.7"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.4.7/buildline_0.4.7_darwin_all.tar.gz"
  sha256 "e54304e0727a69c0fbabf37bdfc8424e8d3c7a51ef0917219885a7d74255da57"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
