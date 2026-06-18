# Homebrew formula for BuildLine. This is the file that lives in the PUBLIC tap
# repo (github.com/thebinarysolution/homebrew-buildline) at Formula/buildline.rb.
# The source stays private; this only points at the compiled release archive.
# Regenerate the url/sha256/version on each release (see docs/RELEASING.md).
class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.3.1"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.3.1/buildline_0.3.1_darwin_all.tar.gz"
  sha256 "d68cd40a1f24ced807b08efd869093b8cceb0ce605331d83bf83ebc861716683"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
