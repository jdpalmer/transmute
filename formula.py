import os
import sys
import hashlib

version = sys.argv[1]
sha1 = hashlib.sha1(file("transmute-" + version + ".tar.gz", "rb").read()).hexdigest()

print("require \"formula\"")
print("")
print("class Transmute < Formula")
print("  homepage \"https://bitbucket.org/jdpalmer/transmute\"")
print("  url \"https://bitbucket.org/jdpalmer/transmute/downloads/transmute-" + version + ".tar.gz\"")
print("  sha1 \"" + sha1 + "\"")
print("")
print("  def install")
print("    ENV['PREFIX'] = prefix")
print("    system \"make\"")
print("    bin.install \"transmute\"")
print("    man1.install \"transmute.1\"")
print("  end")
print("")
print("end")
