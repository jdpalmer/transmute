transmute(1) - convert image formats with Quartz
================================================

## SYNOPSIS

`transmute` [options] [`source-file`] [`target-file`]
`transmute` [`-h` | `-?`]
`transmute` [`-l` | `-L`]

## DESCRIPTION

`transmute` is a command line utility for MacOS that uses Cocoa and
Quartz APIs to convert to and from various macOS supported image
formats.  It has a number of neat features like POSIX input and output
pipes for integration with [NetPBM](https://netpbm.sourceforge.net/),
copying to or from the clipboard, and PDF page selection.

`transmute` is developed with GitHub:

[https://github.com/jdpalmer/transmute](https://github.com/jdpalmer/transmute)

## INSTALLATION

`transmute` can easily be installed with [brew](https://brew.sh/):

    brew tap jdpalmer/homebrew
    brew install transmute

`transmute` can then be upgraded with:

    brew update && brew upgrade transmute

or uninstalled with:

    brew uninstall transmute

If you would like to build `transmute` without `brew`, clone the
`transmute` repository from GitHub and do the usual Makefile dance:

    cd transmute
    make
    make install

## USAGE

In the simplest case, `transmute`, takes a `source-file` as input and
produces a `target-file` as long as each file is one of the many
formats that macOS supports, including but not limited to:

* AVIF (MacOS >= 13)
* BMP
* EPS (`source-file` only; MacOS < 14)
* GIF
* HEIC / HEIF
* ICO
* JPEG
* JPEG 2000
* JPEG-XL (MacOS >= 14)
* PDF
* PBM / PGM / PPM / PAM (`source-file` only)
* PICT (`source-file` only)
* PNG
* PS (`source-file` only; MacOS < 14)
* PSD
* RAW (DNG, CR2, NEF, ARW, etc.; `source-file` only)
* SGI
* SVG (`source-file` only; MacOS >= 14)
* TGA
* TIFF
* WebP

`transmute` automatically detects if the source or target is from
stdin or stdout. The ability to integrate with Unix pipes (stdin,
stdout) is particularly convenient when working with netpbm(1)
pipelines.

Several options affect the data source and data target:

* `-c`:
  Read the source data from the clipboard.

* `-C`:
  Write the target data to the clipboard.

* `-f target-format`:
  Write the target data using the format specified by `target-format`
  (e.g., gif, jpeg, png). This option will override the format implied
  by the `target-file` extension.  It may also be used to set the
  format when the target cannot be inferred from stdout. This option
  has no effect when the target is the clipboard.

* `-q quality`:
  Set the compression quality for the target image to `quality`. The
  value must be between 0.0 and 1.0, where 1.0 is the highest quality.
  This option is only supported for lossy formats like JPEG and HEIC.

* `-i`:
  Do not auto-detect stdin and stdout as source and target.

* `-n pageno`:
  Set the page number to be rendered to `pageno`. Page numbers begin
  at one, which is also the default. PDFs are the only supported
  format with more than one page.

A *proposed* rectangle can also be set for the conversion but the
effect that this rectangle has on the conversion is based on the
implementation of `NSImage`. Typically, the proposed rectangle is
used to set the target resolution for resolution independent images.
The proposed rectangle is *not* intended as a mechanism to robustly
scale a bitmap image. The proposed rectangle dimensions are set with
these options:

* `-W width`:
  Set the proposed width to `width`. If `-H` is not also used then the
  height will be calculated to preserve the `source-file` aspect ratio.

* `-H height`:
  Set the proposed height to `height`. If `-W` is not also used then the
  width will be calculated to preserve the `source-file` aspect ratio.

Two debugging options are available, which list the formats supported
by MacOS's Image I/O infrastructure:

* `-l`:
  Print the result of `CGImageSourceCopyTypeIdentifiers()`

* `-L`:
  Print the result of `CGImageDestinationCopyTypeIdentifiers()`

`transmute` has functionality that overlaps sips(1),
convert(1), and netpbm(1) but is distinguished by supporting vector
formats (unlike `sips`) and having no dependency on Ghostscript or
other libraries not provided by the system (unlike `convert` and
`netpbm`). At the same time, `transmute` does not provide the
graphics judo that these other tools do and is intended to be
complementary.

## EXAMPLES

Convert an input image in TIFF format to an output image in PNG format:

    transmute input.tiff output.png

Convert the clipboard to a PNG image called target.png.

    transmute -c target.png

Load an image into the clipboard.

    transmute -C source.png

Convert the third page of a PDF to a JPEG with a proposed width of 800:

    transmute -n 3 -W 800 source.pdf target.jpeg

Thumbnail an Adobe RAW file with netpbm(1):

    transmute < source.dng | pngtopnm | pnmscale -xy 100 100 | pnmtopng > target.png

Transmute can be used with the LyX Document Processor to provide many
graphical conversions, which usually depend on Ghostscript. These can
be added by editing the preferences file,  `/Library/Application
Support/LyX-2.1/preferences`, and appending these lines:

    \converter "pdf" "png" "transmute -i $$i $$o" ""

In MacOS 14 Sonoma (2023) Apple deprecated EPS and PS support. Earlier
versions of MacOS could also convert EPS and PS, making these LyX rules
handy:

    \converter "ps" "png" "transmute -i $$i $$o" ""
    \converter "eps" "png" "transmute -i $$i $$o" ""
    \converter "eps" "pdf6" "transmute -i $$i $$o" ""

## AUTHOR

Copyright (C) 2014-2026, James Palmer.

