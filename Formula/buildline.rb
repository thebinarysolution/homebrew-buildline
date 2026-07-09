# Homebrew formula for BuildLine. This is the file that lives in the PUBLIC tap
# repo (github.com/thebinarysolution/homebrew-buildline) at Formula/buildline.rb.
# The source stays private; this only points at the compiled release archive.
# Regenerate the url/sha256/version on each release (see docs/RELEASING.md).
class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.4.6"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.4.6/buildline_0.4.6_darwin_all.tar.gz"
  sha256 "ebc65edd44aa71d4eebb59acbe52d27eb8385d167a9b8d25410f618b2fd71a35"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
