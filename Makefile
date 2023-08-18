include definitions.mk

### Rules
.PHONY: all
all: build

prebuild:

.PHONY: build
build: DEPS != find 'src' -type f
build: $(DEPS) prebuild
	$(MKDIR) -p $(BUILDPLATFORMDIR)
	$(CP) -R $(SRCDIR)/* $(BUILDPLATFORMDIR)
ifeq ($(WMOD_DVPLIZE), y)
	$(CD) $(BUILDPLATFORMDIR) && $(DVPL) encrypt --delete-original
endif

.PHONY: install
install: build
	$(CP) -R $(BUILDPLATFORMDIR)/** $(WMOD_INSTALLDIR)

# Generate description by concatenating mod description, FAQ and link to source code.
.PHONY: description
description: $(DESCFILE)

$(DESCFILE): $(WMOD_INFOFILE)
	$(YAML_EVAL) '.mod_entry.description.$(WMOD_DESCRIPTION_LANGUAGE), .mod_entry.faq.$(WMOD_DESCRIPTION_LANGUAGE)[]' $< 1>$@

# Create release on GitHub
.PHONY: release
release:
	$(GH) release create -t $(WMOD_VERSION) $(WMOD_VERSION) $(shell $(FIND) $(DISTDIR) -name "*.$(WMOD_PACKAGE_FORMAT)")

# build packages in general format
.PHONY: dist-general
dist-general: DISTDIR = dist/general
dist-general: build
	$(CD) $(BUILDDIR)/$(WMOD_TARGET_PLATFORM) && $(7Z) a $(_ROOT)/$(DISTDIR)/$(WMOD_PACKAGENAME).$(WMOD_PACKAGE_FORMAT) $(WOTB_PREFIX)

# build packages as required by Forblitz
.PHONY: dist-forblitz
dist-forblitz: DISTDIR = dist/forblitz
dist-forblitz:
dist-forblitz: build
	$(MKDIR) -p $(DISTDIR)
	$(foreach $(WMOD_TARGET_PLATFORM),android pc,$(dist_forblitz_package)
define dist-forblitz-package =
WMOD_PACKAGE_NAME = $(WMOD_NAME)_$(WMOD_VERSION)_$(WMOD_TARGET_PLATFORM)
ifeq ($(WMOD_TARGET_PLATFORM), pc)
	$(eval WMOD_PACKAGENAME = $(WMOD_NAME)_$(WMOD_VERSION)_steam)
endif
	$(CD) $(BUILDDIR)/$(WMOD_TARGET_PLATFORM) && $(7Z) a $(_ROOT)/$(DISTDIR)/$(WMOD_PACKAGE_NAME).$(WMOD_PACKAGE_FORMAT) $(WOTB_PREFIX)
endef

# build packages for distributing
.PHONY: dist
dist: dist-general

# Clean packages
.PHONY: distclean
distclean:
	$(RM) -r -f $(DISTDIR)

# Clean build artifacts
.PHONY: buildclean
buildclean:
	$(RM) -r -f $(BUILDDIR)

# Clean all
.PHONY: clean
clean: distclean buildclean
