// ## Introduction
//
// This is the annotated source code to `transmute`, a command line
// utility for OS X, which uses the Cocoa and Quartz APIs to convert
// to and from various OS X supported image formats.  You can learn
// more about `transmute` at:
//
//    https://bitbucket.org/jdpalmer/transmute
//
// ## License
//
// Copyright (C) 2014-2021 James Palmer.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
// or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
// ## Source Code

#include "version.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// `transmute` depends on graphics operations provided in the
// Cocoa and Quartz APIs to convert image files from one format to
// another.

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>

// The `displayUsage()` function is used to provide help from the
// command line.  After displaying a message about proper usage, the
// function terminates the program normally.

void displayUsage() {
  printf("transmute " VERSION "\n"
         "\n"
         "Usage: transmute [options] [<source-file>] [<target-file>]\n"
         "       transmute [-h | -?]\n"
         "       transmute [-l | -L]\n"
         "\n"
         "transmute auto-detects if the source or target is from stdin or "
         "stdout.\n"
         "\n"
         "Options include:\n"
         "\n"
         "  -W <width> - Set the proposed width.\n"
         "  -H <height> - Set the proposed height.\n"
         "  -n <pageno> - Set the pageno (default=1)\n"
         "  -c - Use clipboard as source-file.\n"
         "  -C - Use clipboard as target-file.\n"
         "  -f <format> - Force the target to be <format>.\n"
         "\n"
         "Supported formats include:\n"
         "\n"
         "  * BMP\n"
         "  * EPS (source-file only)\n"
         "  * GIF\n"
         "  * ICO\n"
         "  * JPEG\n"
         "  * JPEG 2000\n"
         "  * PDF\n"
         "  * PICT (source-file only)\n"
         "  * PNG\n"
         "  * PS (source-file only)\n"
         "  * PSD\n"
         "  * TGA\n"
         "  * TIFF\n"
         "  * and many others (source-file only)\n");

  exit(0);
}

// Helper functions are used for checking constraints and parsing
// integers.

void _require(BOOL truth, char *message) {
  if (truth)
    return;
  fprintf(stderr, "%s\n", message);
  exit(-1);
}

void _disallow(BOOL truth, char *message) { _require(!truth, message); }

int _atoi(char *s) {
  char *endptr;
  int result = (int)strtol(s, &endptr, 10);
  _require(*endptr == 0, "transmute: expected integer argument.");
  return result;
}

// We define our own function for creating an `NSData`
// representation modelled on `NSBitmapImageRep`'s
// `representationUsingType` method. The difference is that this
// function use the path extension to lookup the UTI and call the
// appropriate image encoding routines.

NSData *representationUsingPath(NSBitmapImageRep *bitmapImage,
                                NSString *path_extension) {

  CFStringRef uti_type = (__bridge CFStringRef)[
      [UTType typeWithFilenameExtension:path_extension] identifier];

  NSMutableData *result = [NSMutableData data];

  NSDictionary *CGProperties = nil;

  CGImageDestinationRef dest = CGImageDestinationCreateWithData(
      (__bridge CFMutableDataRef)result, uti_type, 1,
      (__bridge CFDictionaryRef)CGProperties);

  CGImageDestinationAddImage(dest, [bitmapImage CGImage],
                             (__bridge CFDictionaryRef)CGProperties);

  CGImageDestinationFinalize(dest);
  CFRelease(dest);
  return result;
}

// The principle work of the program happens in the `main` function.

int main(int argc, char *argv[]) {

  NSString *sourceFile = nil;
  NSString *targetFile = nil;
  NSString *targetFileExtension = nil;

  BOOL usePipeSource = NO;
  BOOL usePipeTarget = NO;
  BOOL usePasteboardSource = NO;
  BOOL usePasteboardTarget = NO;

  char *optionString = "W:H:n:f:h?cClLiv";

  NSImage *nsImage = nil;

  int pageNumber = 1;
  int width = 0;
  int height = 0;

  CFArrayRef sourceTypes;
  CFArrayRef targetTypes;

  // We can detect if stdin or stdout is being used as input or
  // output with `isatty`.  The downside is that if this command is
  // evaluated by another program, it will get confused because the
  // calling program will typically provide a non tty based stdin and
  // stdout. The `-i` flag is provided to override this
  // autodetection.

  if (isatty(STDIN_FILENO) == 0) {
    usePipeSource = YES;
  }

  if (isatty(STDOUT_FILENO) == 0) {
    usePipeTarget = YES;
  }

  // Next, we process the options described in `displayUsage`.

  int opt = getopt(argc, argv, optionString);
  while (opt != -1) {
    switch (opt) {
    case 'W':
      _require(optarg != nil, "transmute: -W expects argument.");
      width = _atoi(optarg);
      _require(width > 0, "transmute: illegal width.");
      break;

    case 'H':
      _require(optarg != nil, "transmute: -H expects argument.");
      height = _atoi(optarg);
      _require(height > 0, "transmute: illegal height.");
      break;

    case 'n':
      _require(optarg != nil, "transmute: -n expects argument.");
      pageNumber = _atoi(optarg) + 1;
      _require(pageNumber > 0, "transmute: illegal height.");
      break;

    case 'c':
      usePasteboardSource = YES;
      break;

    case 'C':
      usePasteboardTarget = YES;
      break;

    case 'f':
      _require(optarg != nil, "transmute: -f expects argument.");
      targetFileExtension =
          [NSString stringWithCString:optarg
                             encoding:[NSString defaultCStringEncoding]];
      break;

    case 'i':
      usePipeSource = NO;
      usePipeTarget = NO;
      break;

    case 'h':
    case '?':
      displayUsage();
      break;

    case 'l':
      sourceTypes = CGImageSourceCopyTypeIdentifiers();
      CFShow(sourceTypes);
      return 0;
      break;

    case 'L':
      targetTypes = CGImageDestinationCopyTypeIdentifiers();
      CFShow(targetTypes);
      return 0;
      break;

    default:
      break;
    }
    opt = getopt(argc, argv, optionString);
  }

  // Once the options are processed, we should be left with the file
  // arguments to the program less those provided by a pipe or the
  // pasteboard.

  int file_count = argc - optind;

  // There are five cases of interest:

  // Case 1. Multiple sources or targets have been identified.

  _disallow(usePipeSource && usePasteboardSource,
            "transmute: source conflict.");
  _disallow(usePipeTarget && usePasteboardTarget,
            "transmute: target conflict.");

  // Case 2. Neither pipe nor pasteboard is a target or a source.

  if (!usePipeSource && !usePipeTarget && !usePasteboardSource &&
      !usePasteboardTarget) {
    if (file_count == 0) {
      displayUsage();
    }
    _require(file_count == 2, "transmute: bad argument count.");
    sourceFile = [NSString stringWithUTF8String:*(argv + optind)];
    targetFile = [NSString stringWithUTF8String:*(argv + (optind + 1))];
    if (targetFileExtension == nil) {
      targetFileExtension = [targetFile pathExtension];
    }
  }

  // Case 3. A pipe or pasteboard is the source.

  if ((usePipeSource || usePasteboardSource) && !usePipeTarget &&
      !usePasteboardTarget) {
    _require(file_count == 1, "transmute: bad argument count.");
    targetFile = [NSString stringWithUTF8String:*(argv + optind)];
    if (targetFileExtension == nil) {
      targetFileExtension = [targetFile pathExtension];
    }
  }

  // Case 4. A pipe or pasteboard is the target.

  if ((usePipeTarget || usePasteboardTarget) && !usePipeSource &&
      !usePasteboardSource) {
    _require(file_count == 1, "transmute: bad argument count.");
    sourceFile = [NSString stringWithUTF8String:*(argv + optind)];
  }

  // Case 5. A pipe or pasteboard is both the target and the source.

  if ((usePipeSource || usePasteboardSource) &&
      (usePipeTarget || usePasteboardTarget)) {
    _require(file_count == 0, "transmute: bad argument count.");
  }

  // The `targetFileExtension` is extracted either from the '-f'
  // switch, the actual target-file extension, or a default (png) used
  // for pipe and pasteboard targets:

  if ((usePipeTarget || usePasteboardTarget) && targetFileExtension == nil) {
    targetFileExtension = @"png";
  }

  // At this point we check that the extension is valid. In theory
  // we could check the extension against the result from
  // `CGImageSourceCopyTypeIdentifiers` but in practice we need a
  // white list of tested formats and extensions.

  _disallow(targetFileExtension == nil || [targetFileExtension length] == 0,
            "transmute: illegal target type.");

  if (!([targetFileExtension caseInsensitiveCompare:@"bmp"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"gif"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"ico"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"jpg"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"jpf"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"jpeg"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"pdf"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"png"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"psd"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"tga"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"tif"] == 0 ||
        [targetFileExtension caseInsensitiveCompare:@"tiff"] == 0)) {
    fprintf(stderr, "transmute: illegal target type.");
    exit(-1);
  }

  // We then load the data into an `NSImage` using `stdin` or directly
  // from a file.  Cocoa/Quartz automatically detects the image's
  // format and selects an appropriate underlying representation. If
  // the image type can't be detected then we exit with an error.

  if (usePasteboardSource) {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    nsImage = [[NSImage alloc] initWithPasteboard:pasteboard];
    _require(nsImage != nil, "transmute: invalid clipboard data");
  } else if (usePipeSource) {
    NSFileHandle *pipeHandle = [NSFileHandle fileHandleWithStandardInput];
    NSData *pipeData = [NSData dataWithData:[pipeHandle readDataToEndOfFile]];
    nsImage = [[NSImage alloc] initWithData:pipeData];
    _require(nsImage != nil, "transmute: invalid data");
  } else {
    nsImage = [[NSImage alloc] initWithContentsOfFile:sourceFile];
    _require(nsImage != nil, "transmute: invalid source path or file");
  }

  // If the file is a PDF then we optionally allow a page number
  // selection argument from the command line. We find the underlying
  // representation and then cast (if appropriate) to get a
  // `NSPDFImageRep` where we can set the page number. If the page
  // number is not valid then we exit with an error.

  {
    NSImageRep *imageRep = [[nsImage representations] lastObject];
    if ([imageRep isMemberOfClass:[NSPDFImageRep class]]) {
      NSPDFImageRep *pdfRep = (NSPDFImageRep *)imageRep;
      _require(pageNumber <= [pdfRep pageCount],
               "transmute: illegal page number.");
      [pdfRep setCurrentPage:pageNumber];
    } else {
      _require(pageNumber == 1, "transmute: illegal page number.");
    }
  }

  // Next we construct the proposed rectangle from the width and
  // height. If no width and height is supplied we use the default
  // rectangle (usually the width and height of the source). If only
  // one parameter is supplied, we construct the second parameter to
  // maintain the width height ratio of the source.  Note that
  // this shouldn't be used for scaling a bitmap image - these are
  // preferences which may be ignored. But for resolution independent
  // sources these are important to set the target resolution.

  NSRect rect;
  NSRect *rectRef = nil;
  int sourceWidth = [nsImage size].width;
  int sourceHeight = [nsImage size].height;

  _disallow([targetFileExtension caseInsensitiveCompare:@"ico"] == 0 &&
                sourceWidth != sourceHeight,
            "transmute: illegal source dimensions for ico (must be square).");

  if (width != 0 || height != 0) {
    _require(sourceWidth > 0, "transmute: illegal source width.");
    _require(sourceHeight > 0, "transmute: illegal source height.");

    if (width) {
      if (height == 0) {
        float ratio = width / (float)sourceWidth;
        height = ratio * sourceHeight;
      }
    } else {
      float ratio = height / (float)sourceHeight;
      width = ratio * sourceWidth;
    }

    rect = NSMakeRect(0, 0, width, height);
    rectRef = &rect;
  }

  // If the target is a PDF we add the NSImage to a pdf page.
  if ([targetFileExtension caseInsensitiveCompare:@"pdf"] == 0) {
    PDFDocument *pdf = [[PDFDocument alloc] init];
    PDFPage *page = [[PDFPage alloc] initWithImage:nsImage];
    [pdf insertPage:page atIndex:0];

    if (usePipeTarget) {
      NSFileHandle *pipeHandle = [NSFileHandle fileHandleWithStandardOutput];
      [pipeHandle writeData:[pdf dataRepresentation]];
    } else {
      [pdf writeToFile:targetFile];
    }
    exit(0);
  }

  // The actual rendering of vector data happens by converting an
  // `NSImage` to a `CGImage` with `CGImageForProposedRect`.

  CGImageRef cgImage = [nsImage CGImageForProposedRect:rectRef
                                               context:nil
                                                 hints:nil];
  _require(cgImage != nil,
           "transmute: could not create CGImage (internal error)");

  // The resulting `CGImage` can then be used as the source for an
  // `NSBitmapImage`,

  NSBitmapImageRep *bitmapImage =
      [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
  _require(bitmapImage != nil,
           "transmute: could not create NSBitmapImageRep (internal error)");

  // which can be placed on the pasteboard

  if (usePasteboardTarget) {
    NSImage *targetImage = [[NSImage alloc] initWithSize:[bitmapImage size]];
    [targetImage addRepresentation:bitmapImage];
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    NSArray *copiedObjects = @[ targetImage ];
    [pasteboard writeObjects:copiedObjects];
    return 0;
  }

  // or can be converted to an `NSData` object.

  NSData *data = representationUsingPath(bitmapImage, targetFileExtension);
  _require(data != nil, "transmute: could not create NSData (internal error)");

  // Finally, we can output the NSData object to `stdout` or to a file.

  if (usePipeTarget) {
    NSFileHandle *pipeHandle = [NSFileHandle fileHandleWithStandardOutput];
    [pipeHandle writeData:data];
  } else {
    [data writeToFile:targetFile atomically:YES];
  }

  return 0;
}
