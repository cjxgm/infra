_package_names_from_PKGBUILD = $(shell cd $(dir $(PKGBUILD)) && env EUID=1 makepkg --packagelist)
_makepkg_target_from_PKGBUILD = makepkg-$(PKGBUILD:packages/%/PKGBUILD=%)
_bump_pkgrel_target_from_PKGBUILD = bump-pkgrel-$(PKGBUILD:packages/%/PKGBUILD=%)
_package_path_from_name = build/repo/$(name).pkg.tar.xz
_dirty_makepkg_targets = $(foreach PKGBUILD,$?,$(_makepkg_target_from_PKGBUILD))
_dirty_makepkg_targets_exclude_private_key = $(filter-out makepkg-private-key,$(_dirty_makepkg_targets))

PKGBUILDs := $(wildcard packages/*/PKGBUILD)
package_names := $(foreach PKGBUILD,$(PKGBUILDs),$(_package_names_from_PKGBUILD))
package_names_exclude_private_key := $(filter-out infra-private-key-%,$(package_names))
packages_exclude_private_key := $(foreach name,$(package_names_exclude_private_key),$(_package_path_from_name))

makepkg_targets := $(foreach PKGBUILD,$(PKGBUILDs),$(_makepkg_target_from_PKGBUILD))
bump_pkgrel_targets := $(foreach PKGBUILD,$(PKGBUILDs),$(_bump_pkgrel_target_from_PKGBUILD))
bump_pkgrel_targets_exclude_private_key := $(filter-out bump-pkgrel-private-key,$(bump_pkgrel_targets))
build_path := $(abspath build)

MAKEFLAGS += --no-print-directory

.PHONY: all clean rebuild
all: build/repo/infra.db.tar.xz
clean:
	rm -rf build/
rebuild:
	@$(MAKE) clean
	@$(MAKE) all

.PHONY: setup unsetup recheckout update-key
setup: secret.key secret.pem unsetup
	git config --add include.path $(shell git rev-parse --show-toplevel)/scripts/git/config
	@$(MAKE) recheckout
unsetup:
	git config --unset-all include.path $(shell git rev-parse --show-toplevel)/scripts/git/config || test $$? -eq 5
	@$(MAKE) recheckout
recheckout:
	rm -f $(shell git rev-parse --git-path index)
	git checkout HEAD -- .
secret.key:
	@$(MAKE) update-key
update-key: secret.pem
	openssl rand 256 | openssl pkeyutl -encrypt -inkey $< | openssl base64 -out secret.key
secret.pem:
	openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 > $@

.PHONY: bump-pkgrel
bump-pkgrel: $(bump_pkgrel_targets_exclude_private_key)

build/repo/infra.db.tar.xz: $(PKGBUILDs) | build/repo/
	$(MAKE) $(_dirty_makepkg_targets_exclude_private_key)
	rm -f $@
	repo-add $@ $(packages_exclude_private_key)

makepkg-%: packages/%/PKGBUILD | build/repo/ build/downloads/ build/cache/
	systemd-run \
		--collect \
		--pipe \
		-p DynamicUser=1 \
		-p User=nobody \
		-p PrivateDevices=1 \
		-p ProtectKernelTunables=1 \
		-p ProtectKernelModules=1 \
		-p ProtectControlGroups=1 \
		-p BindPaths=$(build_path):/build \
		-p BindReadOnlyPaths=$(abspath .):/source \
		-p InaccessiblePaths=/var/lib/pacman \
		-p WorkingDirectory=/source/packages/$* \
		-E PKGDEST=/build/repo \
		-E SRCDEST=/build/downloads \
		-E BUILDDIR=/tmp \
		-E PACKAGER="$(PACKAGER)" \
		-- \
		makepkg --nodeps --force

bump-pkgrel-%:
	perl -pe 's{\bpkgrel=\K(\d+)}{$$&+1}e' -i "packages/$*/PKGBUILD"

.PRECIOUS: build/ build/%/
build/:
	mkdir $@
	setfacl -nm o::rwX,d:o::rwX $@
build/%/: | build/
	mkdir $@

