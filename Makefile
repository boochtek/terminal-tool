PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall test

install:
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 terminal.sh $(DESTDIR)$(BINDIR)/terminal

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/terminal

test:
	bats test/
