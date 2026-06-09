PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man/man1
VERSION = 26.2

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
	rm -rf tests/target*
	rm -rf tests/__pycache__
	rm -f transmute version.h
	rm -f .\#*
	rm -f *.gz Formula/transmute.rb

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

define FORMULA_TEMPLATE
class Transmute < Formula
  desc "Convert image formats with Quartz"
  homepage "https://github.com/jdpalmer/transmute"
  url "https://github.com/jdpalmer/transmute/archive/refs/tags/v$(VERSION).tar.gz"
  sha256 "REPLACE_SHA"
  license "Apache-2.0"
  head "https://github.com/jdpalmer/transmute.git", branch: "master"

  depends_on :macos

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    output = shell_output("#{bin}/transmute -h")
    assert_match "transmute", output
  end
end
endef
export FORMULA_TEMPLATE

# Create a source tarball
dist:
	@echo "Creating source tarball $(DISTNAME)"
	@git archive --format=tar.gz -o $(DISTNAME) --prefix=transmute-$(VERSION)/ HEAD

# Compute sha256 for the tarball
checksum: dist
	@echo "Computing sha256($(DISTNAME))"
	@shasum -a 256 $(DISTNAME) | awk '{print $$1}' > $(DISTNAME).sha256

# Generate Formula/transmute.rb from template
generate-formula: checksum
	@mkdir -p Formula
	@SHA=$$(cat $(DISTNAME).sha256); \
	echo "$$FORMULA_TEMPLATE" | sed "s/REPLACE_SHA/$$SHA/g" > Formula/transmute.rb

# Create an annotated git tag for the current VERSION
tag:
	@if git rev-parse "v$(VERSION)" >/dev/null 2>&1; then \
		echo "Tag v$(VERSION) already exists."; \
	else \
		git diff --quiet || (echo "Working tree not clean. Commit or stash changes before tagging." && false); \
		git tag -a v$(VERSION) -m "Release v$(VERSION)"; \
	fi

# Create GitHub release and upload tarball, then publish to Homebrew tap
release: tag generate-formula tap-publish
	@echo "Creating GitHub release v$(VERSION) and uploading $(DISTNAME)"
	@git push origin v$(VERSION) --force || true
	@gh release create v$(VERSION) --title "v$(VERSION)" --notes "Release v$(VERSION)" $(DISTNAME) || echo "gh release create failed or release already exists."

# Push formula to the tap and open PR
tap-publish: generate-formula
	@echo "Publishing formula to jdpalmer/homebrew (branch add/transmute-$(VERSION))"
	@if [ ! -d "homebrew" ]; then gh repo clone jdpalmer/homebrew -- -q; fi
	@cd homebrew; \
		git fetch origin -q; \
		git checkout main -q || git checkout master -q; \
		git reset --hard origin/main || git reset --hard origin/master; \
		git checkout -B add/transmute-$(VERSION) -q; \
		mkdir -p Formula; \
		cp ../Formula/transmute.rb Formula/; \
		git add Formula/transmute.rb; \
		if ! git diff --cached --quiet; then \
			git commit -m "homebrew: add transmute formula (v$(VERSION))"; \
			git push -f --set-upstream origin add/transmute-$(VERSION); \
		else \
			echo "No changes to commit in homebrew tap."; \
		fi
	@cd homebrew; \
		if ! gh pr list --head add/transmute-$(VERSION) --state open | grep -q "add/transmute-$(VERSION)"; then \
			gh pr create --title "Add transmute formula (v$(VERSION))" --body "Adds transmute formula (v$(VERSION))." --head add/transmute-$(VERSION) --base main || \
			gh pr create --title "Add transmute formula (v$(VERSION))" --body "Adds transmute formula (v$(VERSION))." --head add/transmute-$(VERSION) --base master || true; \
		else \
			echo "Pull request already exists."; \
		fi

# How to make a release:
#
# 1. Update VERSION in this Makefile.
# 2. Build: `make clean; make`
# 3. Commit the version bump: `git commit -am "Bump version to $(VERSION)"`
# 4. Push the changes: `git push`
# 5. Release: `make release`
# 6. This will tag, generate the formula, upload the release to GitHub,
#    and open a PR in the Homebrew tap.

