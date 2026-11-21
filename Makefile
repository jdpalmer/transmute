PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man/man1
VERSION := $(shell tr -d '[:space:]' < VERSION)

all: transmute transmute.1

transmute: transmute.m version.h
	clang -O3 -g -Wall -Wextra -Wpedantic -fobjc-arc transmute.m -framework Foundation -framework CoreGraphics -framework Quartz -framework Cocoa -framework UniformTypeIdentifiers -o transmute

version.h: transmute.m Makefile VERSION
	echo "#define VERSION \"$(VERSION)\"" > version.h

transmute.1: README.md
	ronn < README.md > transmute.1

install:
	install -d $(BINDIR) $(MANDIR) $(PREFIX)/share/doc/transmute
	install -m755 transmute $(BINDIR)
	install -m644 transmute.1 $(MANDIR)
	install -m644 LICENSE $(PREFIX)/share/doc/transmute/LICENSE

uninstall:
	rm -f $(BINDIR)/transmute
	rm -f $(MANDIR)/transmute.1
	rm -f $(PREFIX)/share/doc/transmute/LICENSE

clean:
	rm -rf tests/target*
	rm -rf tests/__pycache__
	rm -f transmute version.h
	rm -f .\#*
	rm -f *.gz *.tar.gz *.sha256
	rm -rf Formula

test:
	@if command -v pytest >/dev/null 2>&1; then \
		pytest tests/tests.py; \
	elif command -v py.test >/dev/null 2>&1; then \
		py.test tests/tests.py; \
	else \
		./transmute -h; \
	fi

dev-setup:
	pip install pytest
	sudo gem install ronn

# Releases (YY.MM.R): use the sibling bump tool — it tags, creates the GitHub
# release, and updates jdpalmer/tap:
#
#   ../bump/bump.sh transmute
#   ../bump/bump.sh transmute 26.11.1

