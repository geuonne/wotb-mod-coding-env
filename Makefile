# Program dependencies
CD = cd
CP = cp
RM = rm
PWD = pwd
FIND = find
MKDIR = mkdir
CUT = cut
GREP = grep
ECHO = echo
SH = sh
CAT = cat
TR = tr
TOUCH = true 1>

CURL = curl
7Z = 7z
DVPL = dvpl_converter
GITHUB = gh
GIT = git
MAKE = make
YQ = yq --no-colors --indent 4
YAMLLINT = yamllint

YAML_EVAL = $(YQ) eval --expression

WMOD_INFO_FILE = mod_info.yaml
WMOD_INFO_GET = 0<$(WMOD_INFO_FILE) $(YAML_EVAL)

# Mod constants
# Mod full name
# WMOD_TITLE =
# One or more of: (pc|android|ios|any)
# WMOD_INITIALTARGETPLATFORM = any
# (N.N.N[+|[-N.N.N]]|any)
# WMOD_INITIALTARGETPATCH = any
# (wg|lg|Any)
# WMOD_INITIALTARGETPUBLISHER = any

# Compress to dvpl (n|y), do compress by default
WMOD_DVPLIZE = y

# Mod variables
WMOD_TARGET_PLATFORM ?= $(WMOD_INFO_GET) '.mod_entry.compatibility.target_platform'
WMOD_TARGET_PUBLISHER ?= $(WMOD_INFO_GET) '.mod_entry.compatibility.target_publisher'
WMOD_TARGET_PATCH ?= $(WMOD_INFO_GET) '.mod_entry.compatibility.target_patch'

REV = HEAD
# version from an annotated tag
WMOD_VERSION != $(GIT) describe --abbrev=0 $(REV) 2>/dev/null

# Package name. Needed for Android packages
WOTB_PACKAGE_NAME = net.wargaming.wot.blitz
ifeq ($(WMOD_TARGET_PUBLISHER), lg)
	WOTB_PACKAGENAME = com.tanksblitz
endif

WMOD_TITLE != $(WMOD_INFO_GET) '.mod_entry.name'
# Mod title suitable for naming a package
WMOD_NAME != $(ECHO) $(WMOD_TITLE) | $(TR) '[:upper:] ' '[:lower:]-'
WMOD_PACKAGE_NAME = $(WMOD_NAME)_$(WMOD_VERSION)_$(WMOD_TARGET_PLATFORM:any=anyplat)_$(WMOD_TARGET_PUBLISHER:any=anypub)_$(WMOD_TARGET_PATCH:any=anypatch)
WMOD_PACKAGE_FORMAT = zip


# platform-specific game prefix, needed for making base directory for packages
# Default none - for anyplat mods
WOTB_PREFIX = .
ifeq ($(WMOD_TARGET_PLATFORM), pc)
	WOTB_PREFIX = Data
endif
ifeq ($(WMOD_TARGET_PLATFORM), android)
	WOTB_PREFIX = $(WOTB_PACKAGENAME)/files/packs
endif

# Default unset (impossible to determine where the game is installed)
WOTB_INSTALLDIR = .
ifeq ($(WMOD_TARGET_PLATFORM), android)
	WOTB_INSTALLDIR = /sdcard/Android/data
endif

# Default unset (impossible to determine where the game is installed)
WMOD_INSTALLDIR = .
ifeq ($(WMOD_TARGET_PLATFORM), android)
	WMOD_INSTALLDIR = $(WOTB_INSTALLDIR)/$(WOTB_PREFIX)
endif

SRCDIR = src
BUILDDIR = build
MEDIADIR = public/media
DESCDIR = public/desc
DISTDIR = dist/general
TOOLSDIR = tools
PROJECTROOT != $(GIT) rev-parse --show-superproject-working-tree
CODING_ENV_ROOT != $(GIT) rev-parse --show-toplevel

BUILDPLATFORMDIR = $(BUILDDIR)/$(WMOD_TARGET_PLATFORM)/$(WOTB_PREFIX)



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

# Language for making description. English by defaut.
# Can be overriden to make description on another language.
WMOD_DESCRIPTION_LANGUAGE = en
DESCFILE = $(DESCDIR)/$(WMOD_DESCRIPTION_LANGUAGE).txt

# Generate description by concatenating mod description, FAQ and link to source code.
.PHONY: descriptions
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
