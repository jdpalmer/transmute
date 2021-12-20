PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man/man1
VERSION = 1.2

all: transmute transmute.1

transmute: transmute.m version.h
	clang -fobjc-arc transmute.m -framework Foundation -framework CoreGraphics -framework Quartz -framework Cocoa -framework UniformTypeIdentifiers -o transmute

version.h: transmute.m Makefile
	echo "#define VERSION \"$(VERSION)\"" > version.h

transmute.1: README.md
	ronn < README.md > transmute.1

install:
	install -m755 transmute $(BINDIR)
	install -m644 transmute.1 $(MANDIR)

uninstall:
	rm -f $(BINDIR)/transmute
	rm -f $(MANDIR)/transmute.1

clean:
	rm -rf docs
	rm -rf tests/target.*
	rm -rf tests/__pycache__
	rm -f transmute version.h
	rm -f .\#*
	rm -f *.gz

docs: transmute.m
	docco -l linear transmute.m

publish:
	cp -f docs/transmute.html ~/Dropbox/sites/jdpalmer.org/docco/

test:
	py.test tests/tests.py

dev-setup:
	sudo pip install pytest
	sudo gem install ronn
	sudo npm install -g docco

archive: clean
	hg archive transmute-$(VERSION).tar.gz -X ".hg*"
	python formula.py $(VERSION) > transmute.rb
