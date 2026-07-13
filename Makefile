# Makefile for optimize

PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
LOCALEDIR ?= $(PREFIX)/share/locale

PACKAGE = optimize

# Find all .po files in po/ directory
PO_FILES = $(wildcard po/*.po)
# Generate .mo file paths in locale/ directory for local testing/build
MO_FILES = $(patsubst po/%.po,locale/%/LC_MESSAGES/$(PACKAGE).mo,$(PO_FILES))

.PHONY: all clean install locales update-po

all: locales

# Create .mo files from .po files
locales: $(MO_FILES)

locale/%/LC_MESSAGES/$(PACKAGE).mo: po/%.po
	@mkdir -p $(dir $@)
	msgfmt -o $@ $<
	@echo "Compiled $< -> $@"

# Update .po files from the source script
update-po:
	./po/update-po.sh

clean:
	rm -rf locale/

install: locales
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 optimize $(DESTDIR)$(BINDIR)/optimize
	install -d $(DESTDIR)$(PREFIX)/share/man/man1
	install -m 644 optimize.1 $(DESTDIR)$(PREFIX)/share/man/man1/optimize.1
	install -d $(DESTDIR)$(PREFIX)/share/man/pt_BR/man1
	install -m 644 optimize.pt_BR.1 $(DESTDIR)$(PREFIX)/share/man/pt_BR/man1/optimize.1
	install -d $(DESTDIR)/var/cache/optimize/build
	install -d $(DESTDIR)/var/cache/optimize/archives
	
	@for mo in locale/*/LC_MESSAGES/optimize.mo; do \
		[ -f "$$mo" ] || continue; \
		lang=$$(echo $$mo | sed 's|^locale/||; s|/LC_MESSAGES/.*||'); \
		install -d $(DESTDIR)$(LOCALEDIR)/$$lang/LC_MESSAGES; \
		install -m 644 $$mo $(DESTDIR)$(LOCALEDIR)/$$lang/LC_MESSAGES/$(PACKAGE).mo; \
	done
