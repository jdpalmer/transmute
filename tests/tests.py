import os
import subprocess

os.chdir("tests")

EX_OK = 0
EX_USAGE = 64
EX_DATAERR = 65
EX_NOINPUT = 66

def call(astring):
    n = subprocess.call(astring, shell=True)
    return n

def check_output(astring):
    return subprocess.check_output(astring, shell=True).decode("utf-8").strip()

def test_png_to_bmp():
    assert call("../transmute -i source.png target.bmp") == EX_OK
    assert  "target.bmp: PC bitmap, Windows 3.x format, 128 x -128 x 24" in check_output("file target.bmp")

def test_png_to_gif():
    assert call("../transmute -i source.png target.gif") == EX_OK
    assert "target.gif: GIF image data, version 87a, 128 x 128" in check_output("file target.gif")

def test_png_to_gif_format():
    assert call("../transmute -i -f gif source.png target.png") == EX_OK
    assert "target.png: GIF image data, version 87a, 128 x 128" in check_output("file target.png")

def test_png_to_ico():
    assert call("../transmute -i source.png target.ico") == EX_OK
    assert "target.ico: MS Windows icon resource - 1 icon" in check_output("file target.ico")

def test_png_to_jpg():
    assert call("../transmute -i source.png target.jpg") == EX_OK
    assert "target.jpg: JPEG image data, JFIF standard 1.01" in check_output("file target.jpg")

def test_png_to_jpf():
    assert call("../transmute -i source.png target.jpf") == EX_OK
    assert "target.jpf: JPEG 2000" in check_output("file target.jpf")

def test_png_to_png():
    assert call("../transmute -i source.png target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")
    assert call("../transmute -i source_crush.png target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")

def test_png_to_psd():
    assert call("../transmute -i source.png target.psd") == EX_OK
    assert "target.psd: Adobe Photoshop Image, 128 x 128, RGB, 3x 8-bit channels" in check_output("file target.psd")

def test_png_to_tga():
    assert call("../transmute -i source.png target.tga") == EX_OK
    assert "target.tga: Targa image data - RGB - RLE 128 x 128" in check_output("file target.tga")

def test_png_to_tiff():
    assert call("../transmute -i source.png target.tiff") == EX_OK
    assert "target.tiff: TIFF image data, big-endian" in check_output("file target.tiff")

def test_bmp_to_png():
    assert call("../transmute -i source.bmp target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")

def test_gif_to_png():
    assert call("../transmute -i source.gif target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGBA, non-interlaced" in check_output("file target.png")

def test_ico_to_png():
    assert call("../transmute -i source.ico target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")

def test_jpg_to_png():
    assert call("../transmute -i source.jpg target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")

def test_jpf_to_png():
    assert call("../transmute -i source.jpf target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")

def test_psd_to_png():
    assert call("../transmute -i source.psd target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")


def test_tga_to_png():
    assert call("../transmute -i source.tga target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")


def test_tiff_to_png():
    assert call("../transmute -i source.tif target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")

def test_pdf_to_png():
    assert call("../transmute -i -W 128 source.pdf target.png") == EX_OK
    assert "target.png: PNG image data" in check_output("file target.png")

def test_pict_to_png():
    assert call("../transmute -i -W 128 source.pct target.png") == EX_OK
    assert "target.png: PNG image data" in check_output("file target.png")

def test_png_to_pdf():
    assert call("../transmute -i source.png target.pdf") == EX_OK
    assert "target.pdf: PDF document" in check_output("file target.pdf")

def test_clipboard():
    assert call("../transmute -i -C source.png") == EX_OK
    assert call("../transmute -i -c target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")

def test_pipe():
    assert call("../transmute < source.png > target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")

def test_pipe_format():
    assert call("../transmute -f gif < source.png > target.png") == EX_OK
    assert "target.png: GIF image data, version 87a, 128 x 128" in check_output("file target.png")

def test_bad_filename():
    assert call("../transmute -i source.xxx target.png") == EX_NOINPUT

def test_bad_format():
    assert call("../transmute -i source.png target.xxx") == EX_USAGE

def test_bad_rect():
    assert call("../transmute -i -W -100 source.png target.png") == EX_USAGE
    assert call("../transmute -i -H -100 source.png target.png") == EX_USAGE

def test_overflow():
    assert call("../transmute -i -W 999999999999999999999 source.png target.png") == EX_USAGE

def test_invalid_int():
    assert call("../transmute -i -W abc source.png target.png") == EX_USAGE
    assert call("../transmute -i -W '' source.png target.png") == EX_USAGE

def test_quality():
    assert call("../transmute -i -q 0.1 source.png target_low.jpg") == EX_OK
    assert call("../transmute -i -q 1.0 source.png target_high.jpg") == EX_OK
    low_size = os.path.getsize("target_low.jpg")
    high_size = os.path.getsize("target_high.jpg")
    assert low_size < high_size

def setup_function(function):
    call("rm -f target.*")

def teardown_function(function):
    call("rm -f target.*")
