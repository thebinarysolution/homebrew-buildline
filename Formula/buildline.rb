# Homebrew formula for BuildLine. This is the file that lives in the PUBLIC tap
# repo (github.com/thebinarysolution/homebrew-buildline) at Formula/buildline.rb.
# The source stays private; this only points at the compiled release archive.
# Regenerate the url/sha256/version on each release (see docs/RELEASING.md).
class Buildline < Formula
  desc "CI/CD for iOS apps — one config, app in the store"
  homepage "https://github.com/thebinarysolution/homebrew-buildline"
  version "0.6.1"
  url "https://github.com/thebinarysolution/homebrew-buildline/releases/download/v0.6.1/buildline_0.6.1_darwin_all.tar.gz"
  sha256 "53be64bdb07611d8d6d473797b8ea6508bfe90a207a5475b7676e4e47186147f"

  depends_on :macos

  def install
    bin.install "buildline"
  end

  test do
    assert_match "buildline version", shell_output("#{bin}/buildline --version")
  end
end
