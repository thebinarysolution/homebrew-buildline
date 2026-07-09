# Homebrew formula for BuildLine. This is the file that lives in the PUBLIC tap
# repo (github.com/thebinarysolution/homebrew-buildline) at Formula/buildline.rb.
# The source stays private; this only points at the compiled release archive.
# Regenerate the url/sha256/version on each release (see docs/RELEASING.md).
class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.4.5"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.4.5/buildline_0.4.5_darwin_all.tar.gz"
  sha256 "fcc51dbc3d53f0bf241309a39ba24692fb433cd92fe2df32ba0ce5cc2f158a3a"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
