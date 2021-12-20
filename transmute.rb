require "formula"

class Transmute < Formula
  homepage "https://github.com/jdpalmer/transmute"
  url "https://github.com/jdpalmer/transmute/archive/refs/heads/master.zip"
  version "1.3"

  def install
    ENV['PREFIX'] = prefix
    system "make"
    bin.install "transmute"
    man1.install "transmute.1"
  end

end
