_package_names_from_PKGBUILD = $(shell cd $(dir $(PKGBUILD)) && env EUID=1 makepkg --packagelist)
_makepkg_target_from_PKGBUILD = makepkg-$(PKGBUILD:/PKGBUILD=)
_package_path_from_name = build/repo/$(name).pkg.tar.xz
_dirty_makepkg_targets = $(foreach PKGBUILD,$?,$(_makepkg_target_from_PKGBUILD))

PKGBUILDs := $(wildcard */PKGBUILD)
package_names := $(foreach PKGBUILD,$(PKGBUILDs),$(_package_names_from_PKGBUILD))
packages := $(foreach name,$(package_names),$(_package_path_from_name))

makepkg_targets := $(foreach PKGBUILD,$(PKGBUILDs),$(_makepkg_target_from_PKGBUILD))
build_path := $(abspath build)

MAKEFLAGS += --no-print-directory

.PHONY: all clean rebuild
all: build/repo/infra.db.tar.xz
clean:
	rm -rf build/
rebuild:
	@$(MAKE) clean
	@$(MAKE) all

build/repo/infra.db.tar.xz: $(PKGBUILDs) | build/repo/
	rm -f $@
	$(MAKE) $(_dirty_makepkg_targets)
	repo-add $@ $(packages)

makepkg-%: %/PKGBUILD | build/repo/ build/downloads/ build/cache/
	systemd-run \
		--collect \
		--pipe \
		-p DynamicUser=1 \
		-p User=nobody \
		-p BindPaths=$(build_path):/build \
		-p BindReadOnlyPaths=$(abspath .):/source \
		-p WorkingDirectory=/source/$* \
		-E PKGDEST=/build/repo \
		-E SRCDEST=/build/downloads \
		-E BUILDDIR=/tmp \
		-- \
		makepkg --nodeps --force

.PRECIOUS: build/ build/%/
build/:
	mkdir $@
	setfacl -nm o::rwX,d:o::rwX $@
build/%/: | build/
	mkdir $@

