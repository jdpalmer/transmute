transmute(1) - convert image formats with Quartz
================================================

## SYNOPSIS

`transmute` [options] [`source-file`] [`target-file`]  
`transmute` [`-h` | `-?`]  
`transmute` [`-l` | `-L`]

## DESCRIPTION

`transmute` is a command line utility for OS X, which uses the
Cocoa and Quartz APIs to convert to and from various OS X supported
image formats.

`transmute` is developed with GitHub:

[https://github.com/jdpalmer/transmute](https://github.com/jdpalmer/transmute)

## INSTALLATION

`transmute` can easily be installed with [brew](http://brew.sh/):

    brew tap jdpalmer/homebrew-jdp
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
formats that OS X supports:

* BMP
* EPS (`source-file` only)
* GIF
* ICO
* JPEG
* JPEG 2000
* PDF
* PICT (`source-file` only)
* PNG
* PS (`source-file` only)
* PSD
* TGA
* TIFF
* and many others (`source-file` only)

`transmute` automatically detects if the source or target is from
stdin or stdout. The ability to integrate with Unix pipes (stdin,
stdout) is particularly convenient when working with netpbm(1)
pipelines.

Several options effect the data source and data target:

* `-c`:
  Read the source data from the clipboard.

* `-C`:
  Write the target data to the clipboard.

* `-f target-format`:
  Write the target data using the format specified by `target-format`
  (e.g., gif, jpeg, png). This option will override the format implied
  by the `target-file` extension.  It may also be used to set the
  format when the target can not be inferred from stdout. This option
  has no effect when the target is the clipboard.

* `-i`:
  Do not auto-detect stdin and stdout as source and target.

* `-n pageno`:
  Set the page number to be rendered to `pageno`. Page numbers begin
  at one, which is also the default. PDFs are the only supported
  format with more than one page.

A *proposed* rectangle can also be set for the conversion but the
effect that this rectangle has on the conversion is based on the
implementation of `NSImage`. Typically, the proposed rectangle is
used to set the target resolution for resolution independent images
(e.g., EPS). The proposed rectangle is *not* intended as a mechanism
to robustly scale a bitmap image. The proposed rectangle dimensions
are set with these options:

* `-W width`:
  Set the proposed width to `width`. If `-H` is not also used then the
  height will be calculated to preserve the `source-file` aspect ratio.

* `-H height`:
  Set the proposed height to `height`. If `-W` is not also used then the
  width will be calculated to preserve the `source-file` aspect ratio.

Two debugging options are available, which list the formats supported
by OS X's Image I/O infrastructure:

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
complimentary.

## EXAMPLES

Convert an input image in EPS format to an output image in PNG format:

    transmute input.eps output.png
    
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

    \converter "ps" "png" "transmute -i $$i $$o" ""
    \converter "eps" "png" "transmute -i $$i $$o" ""
    \converter "pdf" "png" "transmute -i $$i $$o" ""
    \converter "eps" "pdf6" "transmute -i $$i $$o" ""

## AUTHOR

`transmute` was written by James Palmer.

[http://jdpalmer.org](http://jdpalmer.org)

## COPYRIGHT

Copyright (C) 2014-2021 James Palmer.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
or implied. See the License for the specific language governing
permissions and limitations under the License.
