// ## Introduction
//
// This is the annotated source code to `transmute`, a command line
// utility for OS X, which uses the Cocoa and Quartz APIs to convert
// to and from various OS X supported image formats.  You can learn
// more about `transmute` at:
//
//    https://github.com/jdpalmer/transmute/
//
// ## License
//
// Copyright (C) 2014-2026 James Palmer.
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
#include <sysexits.h>
#include <errno.h>
#include <limits.h>

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
         "  -q <quality> - Set the compression quality (0.0-1.0).\n"
         "\n"
         "Supported formats include:\n"
         "\n"
         "  * BMP\n"
         "  * EPS (source-file only; MacOS < 14)\n"
         "  * GIF\n"
         "  * ICO\n"
         "  * JPEG\n"
         "  * JPEG 2000\n"
         "  * PDF\n"
         "  * PICT (source-file only)\n"
         "  * PNG\n"
         "  * PS (source-file only; MacOS < 14)\n"
         "  * PSD\n"
         "  * TGA\n"
         "  * TIFF\n"
         "  * and many others (source-file only)\n");

  exit(EX_OK);
}

// Helper functions are used for checking constraints and parsing
// integers.

void _require(BOOL truth, char *message, int exit_code) {
  if (truth)
    return;
  fprintf(stderr, "%s\n", message);
  exit(exit_code);
}

void _disallow(BOOL truth, char *message, int exit_code) {
  _require(!truth, message, exit_code);
}

int _atoi(char *s) {
  char *endptr;
  errno = 0;
  long result = strtol(s, &endptr, 10);

  _require(s != endptr && *s != '\0', "transmute: expected integer argument.",
           EX_USAGE);
  _require(*endptr == '\0', "transmute: expected integer argument.", EX_USAGE);
  _require(errno != ERANGE || (result != LONG_MIN && result != LONG_MAX),
           "transmute: integer out of range.", EX_USAGE);
  _require(result >= INT_MIN && result <= INT_MAX,
           "transmute: integer out of range.", EX_USAGE);

  return (int)result;
}

double _atof(char *s) {
  char *endptr;
  errno = 0;
  double result = strtod(s, &endptr);
  _require(s != endptr && *s != '\0', "transmute: expected float argument.",
           EX_USAGE);
  _require(*endptr == '\0', "transmute: expected float argument.", EX_USAGE);
  _require(errno != ERANGE, "transmute: float out of range.", EX_USAGE);
  return result;
}

// We define our own function for creating an `NSData`
// representation modelled on `NSBitmapImageRep`'s
// `representationUsingType` method. The difference is that this
// function use the path extension to lookup the UTI and call the
// appropriate image encoding routines.

NSData *representationUsingPath(NSBitmapImageRep *bitmapImage,
                                NSString *path_extension,
                                NSDictionary *properties) {

  UTType *type = [UTType typeWithFilenameExtension:path_extension];
  if (!type) {
    return nil;
  }

  CFStringRef uti_type = (__bridge CFStringRef)[type identifier];
  if (!uti_type) {
    return nil;
  }

  NSMutableData *result = [NSMutableData data];

  CGImageDestinationRef dest = CGImageDestinationCreateWithData(
      (__bridge CFMutableDataRef)result, uti_type, 1,
      (__bridge CFDictionaryRef)properties);

  if (dest == NULL) {
    return nil;
  }

  CGImageDestinationAddImage(dest, [bitmapImage CGImage],
                             (__bridge CFDictionaryRef)properties);

  bool finalized = CGImageDestinationFinalize(dest);
  CFRelease(dest);

  if (!finalized) {
    return nil;
  }

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

  char *optionString = "W:H:n:f:q:cCih?lL";

  NSImage *nsImage = nil;

  int pageNumber = 1;
  int width = 0;
  int height = 0;
  double quality = -1.0;

  CFArrayRef sourceTypes;

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
      _require(optarg != NULL, "transmute: -W expects argument.", EX_USAGE);
      width = _atoi(optarg);
      _require(width > 0, "transmute: illegal width.", EX_USAGE);
      break;

    case 'H':
      _require(optarg != NULL, "transmute: -H expects argument.", EX_USAGE);
      height = _atoi(optarg);
      _require(height > 0, "transmute: illegal height.", EX_USAGE);
      break;

    case 'n':
      _require(optarg != NULL, "transmute: -n expects argument.", EX_USAGE);
      pageNumber = _atoi(optarg);
      _require(pageNumber > 0, "transmute: illegal page number.", EX_USAGE);
      break;

    case 'c':
      usePasteboardSource = YES;
      break;

    case 'C':
      usePasteboardTarget = YES;
      break;

    case 'f':
      _require(optarg != NULL, "transmute: -f expects argument.", EX_USAGE);
      targetFileExtension = [NSString stringWithUTF8String:optarg];
      break;

    case 'q':
      _require(optarg != NULL, "transmute: -q expects argument.", EX_USAGE);
      quality = _atof(optarg);
      _require(quality >= 0.0 && quality <= 1.0,
               "transmute: illegal quality value (must be 0.0-1.0).", EX_USAGE);
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
      CFRelease(sourceTypes);
      return EX_OK;
      break;

    case 'L':
      {
        CFArrayRef targetTypesArray = CGImageDestinationCopyTypeIdentifiers();
        CFShow(targetTypesArray);
        CFRelease(targetTypesArray);
        return EX_OK;
      }
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
            "transmute: source conflict.", EX_USAGE);
  _disallow(usePipeTarget && usePasteboardTarget,
            "transmute: target conflict.", EX_USAGE);

  // Case 2. Neither pipe nor pasteboard is a target or a source.

  if (!usePipeSource && !usePipeTarget && !usePasteboardSource &&
      !usePasteboardTarget) {
    if (file_count == 0) {
      displayUsage();
    }
    _require(file_count == 2, "transmute: bad argument count.", EX_USAGE);
    sourceFile = [NSString stringWithUTF8String:*(argv + optind)];
    targetFile = [NSString stringWithUTF8String:*(argv + (optind + 1))];
    if (targetFileExtension == nil) {
      targetFileExtension = [targetFile pathExtension];
    }
  }

  // Case 3. A pipe or pasteboard is the source.

  if ((usePipeSource || usePasteboardSource) && !usePipeTarget &&
      !usePasteboardTarget) {
    _require(file_count == 1, "transmute: bad argument count.", EX_USAGE);
    targetFile = [NSString stringWithUTF8String:*(argv + optind)];
    if (targetFileExtension == nil) {
      targetFileExtension = [targetFile pathExtension];
    }
  }

  // Case 4. A pipe or pasteboard is the target.

  if ((usePipeTarget || usePasteboardTarget) && !usePipeSource &&
      !usePasteboardSource) {
    _require(file_count == 1, "transmute: bad argument count.", EX_USAGE);
    sourceFile = [NSString stringWithUTF8String:*(argv + optind)];
  }

  // Case 5. A pipe or pasteboard is both the target and the source.

  if ((usePipeSource || usePasteboardSource) &&
      (usePipeTarget || usePasteboardTarget)) {
    _require(file_count == 0, "transmute: bad argument count.", EX_USAGE);
  }

  // The `targetFileExtension` is extracted either from the '-f'
  // switch, the actual target-file extension, or a default (png) used
  // for pipe and pasteboard targets:

  if ((usePipeTarget || usePasteboardTarget) && targetFileExtension == nil) {
    targetFileExtension = @"png";
  }

  // At this point we check that the extension is valid. We use UTType
  // to dynamically check if the system supports writing to this format.

  _disallow(targetFileExtension == nil || [targetFileExtension length] == 0,
            "transmute: illegal target type.", EX_USAGE);

  UTType *type = [UTType typeWithFilenameExtension:targetFileExtension];
  _require(type != nil && ([type conformsToType:UTTypeImage] || [type conformsToType:UTTypePDF]),
           "transmute: illegal target type.", EX_USAGE);

  CFArrayRef targetTypesArray = CGImageDestinationCopyTypeIdentifiers();
  BOOL supported = NO;
  for (CFIndex i = 0; i < CFArrayGetCount(targetTypesArray); i++) {
    CFStringRef supported_uti = CFArrayGetValueAtIndex(targetTypesArray, i);
    UTType *supportedType = [UTType typeWithIdentifier:(__bridge NSString *)supported_uti];
    if (supportedType && [type conformsToType:supportedType]) {
      supported = YES;
      break;
    }
  }
  CFRelease(targetTypesArray);

  _require(supported, "transmute: unsupported target type.", EX_USAGE);

  // We then load the data into an `NSImage` using `stdin` or directly
  // from a file.  Cocoa/Quartz automatically detects the image's
  // format and selects an appropriate underlying representation. If
  // the image type can't be detected then we exit with an error.

  if (usePasteboardSource) {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    nsImage = [[NSImage alloc] initWithPasteboard:pasteboard];
    _require(nsImage != nil, "transmute: invalid clipboard data", EX_DATAERR);
  } else if (usePipeSource) {
    NSFileHandle *pipeHandle = [NSFileHandle fileHandleWithStandardInput];
    NSData *pipeData = [NSData dataWithData:[pipeHandle readDataToEndOfFile]];
    nsImage = [[NSImage alloc] initWithData:pipeData];
    _require(nsImage != nil, "transmute: invalid data", EX_DATAERR);
  } else {
    nsImage = [[NSImage alloc] initWithContentsOfFile:sourceFile];
    _require(nsImage != nil, "transmute: invalid source path or file",
             EX_NOINPUT);
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
               "transmute: illegal page number.", EX_USAGE);
      [pdfRep setCurrentPage:pageNumber - 1];
    } else {
      _require(pageNumber == 1, "transmute: illegal page number.", EX_USAGE);
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
  CGFloat sourceWidth = [nsImage size].width;
  CGFloat sourceHeight = [nsImage size].height;

  _disallow([targetFileExtension caseInsensitiveCompare:@"ico"] == 0 &&
                sourceWidth != sourceHeight,
            "transmute: illegal source dimensions for ico (must be square).",
            EX_USAGE);

  if (width != 0 || height != 0) {
    _require(sourceWidth > 0, "transmute: illegal source width.", EX_DATAERR);
    _require(sourceHeight > 0, "transmute: illegal source height.", EX_DATAERR);

    if (width) {
      if (height == 0) {
        CGFloat ratio = width / sourceWidth;
        height = (int)(ratio * sourceHeight);
      }
    } else {
      CGFloat ratio = height / sourceHeight;
      width = (int)(ratio * sourceWidth);
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
    exit(EX_OK);
  }

  // The actual rendering of vector data happens by converting an
  // `NSImage` to a `CGImage` with `CGImageForProposedRect`.

  CGImageRef cgImage = [nsImage CGImageForProposedRect:rectRef
                                               context:nil
                                                 hints:nil];
  _require(cgImage != nil,
           "transmute: could not create CGImage (internal error)", EX_SOFTWARE);

  // The resulting `CGImage` can then be used as the source for an
  // `NSBitmapImage`,

  NSBitmapImageRep *bitmapImage =
      [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
  _require(bitmapImage != nil,
           "transmute: could not create NSBitmapImageRep (internal error)",
           EX_SOFTWARE);

  // which can be placed on the pasteboard

  if (usePasteboardTarget) {
    NSImage *targetImage = [[NSImage alloc] initWithSize:[bitmapImage size]];
    [targetImage addRepresentation:bitmapImage];
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    NSArray *copiedObjects = @[ targetImage ];
    [pasteboard writeObjects:copiedObjects];
    return EX_OK;
  }

  // or can be converted to an `NSData` object.

  NSDictionary *properties = nil;
  if (quality >= 0.0) {
    properties = @{(NSString *)kCGImageDestinationLossyCompressionQuality: @(quality)};
  }

  NSData *data = representationUsingPath(bitmapImage, targetFileExtension, properties);
  _require(data != nil, "transmute: could not create NSData (internal error)",
           EX_SOFTWARE);

  // Finally, we can output the NSData object to `stdout` or to a file.

  if (usePipeTarget) {
    NSFileHandle *pipeHandle = [NSFileHandle fileHandleWithStandardOutput];
    [pipeHandle writeData:data];
  } else {
    [data writeToFile:targetFile atomically:YES];
  }

  return EX_OK;
}
