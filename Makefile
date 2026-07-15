PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
LOCALEDIR ?= $(PREFIX)/share/locale

PACKAGE = optimize
SHFMT_FLAGS = -i 4 -ci -sr
SHELL_SCRIPTS = optimize $(wildcard scripts/*.sh) $(wildcard tests/*.sh)

PO_FILES = $(wildcard po/*.po)
MO_FILES = $(patsubst po/%.po,locale/%/LC_MESSAGES/$(PACKAGE).mo,$(PO_FILES))

.PHONY: all bootstrap-dev check clean format install lint locales test update-po verify-tools

all: locales

locales: $(MO_FILES)

locale/%/LC_MESSAGES/$(PACKAGE).mo: po/%.po
	@mkdir -p $(dir $@)
	msgfmt -o $@ $<
	@echo "Compiled $< -> $@"

bootstrap-dev:
	./scripts/bootstrap-dev.sh

verify-tools:
	./scripts/check-dev-tools.sh

lint: verify-tools
	@set -e; for script in $(SHELL_SCRIPTS); do bash -n "$$script"; done
	shellcheck $(SHELL_SCRIPTS)
	shfmt -d $(SHFMT_FLAGS) $(SHELL_SCRIPTS)

format: verify-tools
	shfmt -w $(SHFMT_FLAGS) $(SHELL_SCRIPTS)

test:
	./tests/test_cli.sh
	./tests/test_version_consistency.sh

check: lint test

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
