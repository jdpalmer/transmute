import os
import subprocess
import pytest

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

@pytest.mark.parametrize("target_ext, expected_file_sig", [
    ("bmp", "PC bitmap, Windows 3.x format, 128 x -128 x 24"),
    ("gif", "GIF image data, version 87a, 128 x 128"),
    ("ico", "MS Windows icon resource - 1 icon"),
    ("jpg", "JPEG image data, JFIF standard 1.01"),
    ("jpf", "JPEG 2000"),
    ("png", "PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced"),
    ("psd", "Adobe Photoshop Image, 128 x 128, RGB, 3x 8-bit channels"),
    ("tga", "Targa image data - RGB - RLE 128 x 128"),
    ("tiff", "TIFF image data, big-endian"),
])
def test_png_to_formats(target_ext, expected_file_sig):
    assert call(f"../transmute -i source.png target.{target_ext}") == EX_OK
    assert expected_file_sig in check_output(f"file target.{target_ext}")

def test_png_crush_to_png():
    assert call("../transmute -i source_crush.png target.png") == EX_OK
    assert "target.png: PNG image data, 128 x 128, 8-bit/color RGB, non-interlaced" in check_output("file target.png")

def test_png_to_gif_format():
    assert call("../transmute -i -f gif source.png target.png") == EX_OK
    assert "target.png: GIF image data, version 87a, 128 x 128" in check_output("file target.png")

@pytest.mark.parametrize("source_file, expected_color_space", [
    ("source.bmp", "8-bit/color RGB, non-interlaced"),
    ("source.gif", "8-bit/color RGBA, non-interlaced"),
    ("source.ico", "8-bit/color RGB, non-interlaced"),
    ("source.jpg", "8-bit/color RGB, non-interlaced"),
    ("source.jpf", "8-bit/color RGB, non-interlaced"),
    ("source.psd", "8-bit/color RGB, non-interlaced"),
    ("source.tga", "8-bit/color RGB, non-interlaced"),
    ("source.tif", "8-bit/color RGB, non-interlaced"),
])
def test_formats_to_png(source_file, expected_color_space):
    assert call(f"../transmute -i {source_file} target.png") == EX_OK
    assert f"target.png: PNG image data, 128 x 128, {expected_color_space}" in check_output("file target.png")

@pytest.mark.parametrize("source_file, expected_color_space", [
    ("source.ppm", "8-bit/color RGB, non-interlaced"),
    ("source.pam", "8-bit/color RGB, non-interlaced"),
])
def test_netpbm_rgb_to_png(source_file, expected_color_space):
    assert call(f"../transmute -i {source_file} target.png") == EX_OK
    assert f"target.png: PNG image data, 4 x 4, {expected_color_space}" in check_output("file target.png")

@pytest.mark.parametrize("source_file", [
    "source.pbm",
    "source.pgm",
])
def test_netpbm_grayscale_to_png(source_file):
    assert call(f"../transmute -i {source_file} target.png") == EX_OK
    assert "target.png: PNG image data, 4 x 4, 8-bit grayscale, non-interlaced" in check_output("file target.png")

def test_pdf_to_png():
    assert call("../transmute -i -W 128 source.pdf target.png") == EX_OK
    assert "target.png: PNG image data" in check_output("file target.png")

def test_pict_to_png():
    assert call("../transmute -i -W 128 source.pct target.png") == EX_OK
    assert "target.png: PNG image data" in check_output("file target.png")

def test_png_to_pdf():
    assert call("../transmute -i source.png target.pdf") == EX_OK
    assert "target.pdf: PDF document" in check_output("file target.pdf")

def test_png_to_pdf_resized():
    assert call("../transmute -i -W 64 source.png target.pdf") == EX_OK
    assert call("../transmute -i target.pdf target.png") == EX_OK
    assert "128 x 128" in check_output("file target.png")

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

def test_batch_conversion():
    os.makedirs("output", exist_ok=True)
    # Use files with names that don't conflict with original sources
    assert call("../transmute -i source.png batch1.png") == EX_OK
    assert call("../transmute -i source.png batch2.png") == EX_OK
    assert call("../transmute -b -f gif -o output batch1.png batch2.png") == EX_OK
    assert "output/batch1.gif: GIF image data" in check_output("file output/batch1.gif")
    assert "output/batch2.gif: GIF image data" in check_output("file output/batch2.gif")

def test_batch_conversion_no_output_dir():
    assert call("../transmute -i source.png batch3.png") == EX_OK
    assert call("../transmute -b -f gif batch3.png") == EX_OK
    assert "batch3.gif: GIF image data" in check_output("file batch3.gif")

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
    assert call("../transmute -i -q 0.5 source.png target.png") == EX_USAGE

def setup_function(function):
    call("rm -f target* batch* source1.png source2.png")
    call("rm -rf output")

def teardown_function(function):
    call("rm -f target* batch* source1.png source2.png")
    call("rm -rf output")
