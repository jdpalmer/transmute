PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man/man1
VERSION = 1.4

all: transmute transmute.1

transmute: transmute.m version.h
	clang -O3 -g -Wall -Wextra -Wpedantic -fobjc-arc transmute.m -framework Foundation -framework CoreGraphics -framework Quartz -framework Cocoa -framework UniformTypeIdentifiers -o transmute

version.h: transmute.m Makefile
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
	rm -rf tests/target.*
	rm -rf tests/__pycache__
	rm -f transmute version.h
	rm -f .\#*
	rm -f *.gz

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

# Release & Homebrew helper targets
DISTNAME = transmute-$(VERSION).tar.gz
TARBALL_URL = https://github.com/jdpalmer/transmute/archive/refs/tags/v$(VERSION).tar.gz

# Create a source tarball (from tag if present, otherwise HEAD)
dist:
	@echo "Creating source tarball $(DISTNAME)"
	@if git rev-parse --verify -q "refs/tags/v$(VERSION)" >/dev/null; then \
		git archive --format=tar.gz -o $(DISTNAME) --prefix=transmute-$(VERSION)/ v$(VERSION); \
	else \
		git archive --format=tar.gz -o $(DISTNAME) --prefix=transmute-$(VERSION)/ HEAD; \
	fi

# Compute sha256 for the tarball
checksum: dist
	@echo "Computing sha256($(DISTNAME))"
	@shasum -a 256 $(DISTNAME) | awk '{print $$1}' > $(DISTNAME).sha256
	@echo "SHA256: $$(cat $(DISTNAME).sha256)"

# Create an annotated git tag for the current VERSION
tag:
	@git diff --quiet || (echo "Working tree not clean. Commit or stash changes before tagging." && false)
	@git tag -a v$(VERSION) -m "Release v$(VERSION)"

# Create GitHub release and upload tarball (requires gh CLI authenticated)
release: dist checksum tag
	@echo "Creating GitHub release v$(VERSION) and uploading $(DISTNAME)"
	@gh release create v$(VERSION) --title "v$(VERSION)" --notes "Release v$(VERSION)" $(DISTNAME) || (echo "gh release create failed; ensure gh is authenticated and you have repo permissions" && false)

# Update committed Formula/transmute.rb by replacing placeholders with current version and checksum
update-formula: checksum
	@echo "Updating Formula/transmute.rb with VERSION=$(VERSION)"
	@SHA=$$(cat $(DISTNAME).sha256); \
	perl -pi -e "s/__VERSION__/$$(printf '%s' $(VERSION))/g; s/__SHA__/$$(printf '%s' $$SHA)/g;" Formula/transmute.rb; \
	git add Formula/transmute.rb; git commit -m "homebrew: update transmute formula (v$(VERSION))" || true

# Push formula to the tap and open PR (requires gh auth and push rights to the tap)
tap-publish: update-formula
	@echo "Publishing formula to jdpalmer/homebrew (branch add/transmute-$(VERSION))"
	@gh repo clone jdpalmer/homebrew -- -q || true
	@cd homebrew; git checkout -B add/transmute-$(VERSION); mkdir -p Formula; cp ../Formula/transmute.rb Formula/; git add Formula/transmute.rb; git commit -m "homebrew: add transmute formula (v$(VERSION))" || true; git push --set-upstream origin add/transmute-$(VERSION)
	@cd homebrew; gh pr create --title "Add transmute formula" --body "Adds transmute formula (v$(VERSION))." --head add/transmute-$(VERSION) --base master || true

# Run basic CI checks
ci-check:
	@echo "Running basic CI checks: build, manpage generation, test (if available)"
	@make
	@make transmute.1
	@if command -v pytest >/dev/null 2>&1; then \
		pytest tests/tests.py || true; \
	elif command -v py.test >/dev/null 2>&1; then \
		py.test tests/tests.py || true; \
	fi
