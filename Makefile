PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
REPO := boochtek/terminal-tool
TAP_FORMULA := ../homebrew-tap/Formula/terminal-tool.rb

.PHONY: install uninstall test release bump-tap version

install:
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 terminal.sh $(DESTDIR)$(BINDIR)/terminal

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/terminal

test:
	bats test/

# Get the current version from the script
version:
	@grep '^VERSION=' terminal.sh | cut -d'"' -f2

# Create a new GitHub release from the current version
# Usage: make release
release: test
	@VERSION=$$(grep '^VERSION=' terminal.sh | cut -d'"' -f2) && \
	echo "Creating release v$$VERSION..." && \
	git tag -a "v$$VERSION" -m "Release v$$VERSION" && \
	git push origin "v$$VERSION" && \
	gh release create "v$$VERSION" --repo $(REPO) --title "v$$VERSION" --generate-notes

# Get the latest release info from GitHub
latest:
	@gh release view --repo $(REPO) --json tagName,publishedAt,url | jq .

# Get SHA256 for the latest release tarball
sha256:
	@VERSION=$$(gh release view --repo $(REPO) --json tagName -q .tagName) && \
	curl -sL "https://github.com/$(REPO)/archive/refs/tags/$$VERSION.tar.gz" | shasum -a 256 | cut -d' ' -f1

# Update the homebrew-tap formula with the latest release
# Usage: make bump-tap
bump-tap:
	@VERSION=$$(gh release view --repo $(REPO) --json tagName -q .tagName) && \
	SHA=$$(curl -sL "https://github.com/$(REPO)/archive/refs/tags/$$VERSION.tar.gz" | shasum -a 256 | cut -d' ' -f1) && \
	echo "Updating $(TAP_FORMULA) to $$VERSION (sha256: $$SHA)" && \
	sed -i '' "s|url \".*\"|url \"https://github.com/$(REPO)/archive/refs/tags/$$VERSION.tar.gz\"|" $(TAP_FORMULA) && \
	sed -i '' "s|sha256 \".*\"|sha256 \"$$SHA\"|" $(TAP_FORMULA) && \
	SEMVER=$${VERSION#v} && \
	sed -i '' "s|assert_match \"[0-9.]*\"|assert_match \"$$SEMVER\"|" $(TAP_FORMULA) && \
	echo "Updated. Don't forget to commit and push homebrew-tap."
