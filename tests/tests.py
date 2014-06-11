# Copyright (C) 2014 James Dean Palmer.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing
# permissions and limitations under the License.
#
# transmute testing is accomplished with Python and pytest.  One
# caveat is that Python's subprocess.call does not emulate stdin and
# stdout as if they were part of an interactive shell (even with
# shell=True). Thus, most tests require transmute's -i flag to disable
# detecting stdin and stdout as input and output.

import os
import subprocess


os.chdir("tests")


def call(astring):
    n = subprocess.call(astring, shell=True)
    if n == 255:
        return -1
    return n


def check_output(astring):
    return subprocess.check_output(astring, shell=True).decode("utf-8").strip()


def test_png_to_bmp():
    assert call("../transmute -i source.png target.bmp") == 0
    assert check_output("file target.bmp") == "target.bmp: PC bitmap, Windows 3.x format, 128 x -128 x 24"


def test_png_to_gif():
    assert call("../transmute -i source.png target.gif") == 0
    assert check_output("file target.gif") == "target.gif: GIF image data, version 87a, 128 x 128"


def test_png_to_gif_format():
    assert call("../transmute -i -f gif source.png target.png") == 0
    assert check_output("file target.png") == "target.png: GIF image data, version 87a, 128 x 128"


def test_png_to_ico():
    assert call("../transmute -i source.png target.ico") == 0
    assert check_output("file target.ico") == "target.ico: MS Windows icon resource - 1 icon"


def test_png_to_jpg():
    assert call("../transmute -i source.png target.jpg") == 0
    assert check_output("file target.jpg") == "target.jpg: JPEG image data, JFIF standard 1.01"


def test_png_to_jpf():
    assert call("../transmute -i source.png target.jpf") == 0
    assert check_output("file target.jpf") == "target.jpf: JPEG 2000 image data"


def test_png_to_png():
    assert call("../transmute -i source.png target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"
    assert call("../transmute -i source_crush.png target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"


def test_png_to_psd():
    assert call("../transmute -i source.png target.psd") == 0
    assert check_output("file target.psd") == "target.psd: Adobe Photoshop Image, 128 x 128, RGB, 3x 8-bit channels"


def test_png_to_tga():
    assert call("../transmute -i source.png target.tga") == 0
    assert check_output("file target.tga") == "target.tga: Targa image data - RGB - RLE 128 x 128"


def test_png_to_tiff():
    assert call("../transmute -i source.png target.tiff") == 0
    assert check_output("file target.tiff") == "target.tiff: TIFF image data, big-endian"


def test_bmp_to_png():
    assert call("../transmute -i source.bmp target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"


def test_gif_to_png():
    assert call("../transmute -i source.gif target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGBA, non-interlaced"


def test_ico_to_png():
    assert call("../transmute -i source.ico target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGBA, non-interlaced"


def test_jpg_to_png():
    assert call("../transmute -i source.jpg target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"


def test_jpf_to_png():
    assert call("../transmute -i source.jpf target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"


def test_psd_to_png():
    assert call("../transmute -i source.psd target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"


def test_tga_to_png():
    assert call("../transmute -i source.tga target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"


def test_tiff_to_png():
    assert call("../transmute -i source.tif target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"


def test_eps_to_png():
    assert call("../transmute -i -W 128 source.eps target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 110, 8-bit/color RGBA, non-interlaced"


def test_pdf_to_png():
    assert call("../transmute -i -W 128 source.pdf target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 79, 8-bit/color RGBA, non-interlaced"


def test_pict_to_png():
    assert call("../transmute -i -W 128 source.pct target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 110, 8-bit/color RGBA, non-interlaced"

def test_png_to_png():
    assert call("../transmute -i source.png target.pdf") == 0
    assert check_output("file target.pdf") == "target.pdf: PDF document, version 1.3"

def test_clipboard():
    assert call("../transmute -i -C source.png") == 0
    assert call("../transmute -i -c target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"


def test_pipe():
    assert call("../transmute < source.png > target.png") == 0
    assert check_output("file target.png") == "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"


def test_pipe_format():
    assert call("../transmute -f gif < source.png > target.png") == 0
    assert check_output("file target.png") == "target.png: GIF image data, version 87a, 128 x 128"


def test_bad_filename():
    assert call("../transmute -i source.xxx target.png") == -1


def test_bad_format():
    assert call("../transmute -i source.png target.xxx") == -1


def test_bad_rect():
    assert call("../transmute -i -W -100 source.png target.png") == -1
    assert call("../transmute -i -H -100 source.png target.png") == -1


def setup_function(function):
    call("rm -f target.*")


def teardown_function(function):
    call("rm -f target.*")
