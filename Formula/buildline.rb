# Homebrew formula for BuildLine. This is the file that lives in the PUBLIC tap
# repo (github.com/thebinarysolution/homebrew-buildline) at Formula/buildline.rb.
# The source stays private; this only points at the compiled release archive.
# Regenerate the url/sha256/version on each release (see docs/RELEASING.md).
class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.2.1"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.2.1/buildline_0.2.1_darwin_all.tar.gz"
  sha256 "57049301cd4e0e1bb288630372f7a05200b13db2be22d1d2e2a6e93cb9392af3"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
