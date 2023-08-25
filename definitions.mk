### Meta
# Statement separator. Useful in "define" blocks for separating shell
# commands.
_STASEP = ;

### Program dependencies
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
SED = sed

MAGICK = magick
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

### Variables
# Compress to dvpl (n|y), do compress by default
WMOD_DVPLIZE = y

# Mod variables
WMOD_TARGET_PLATFORM != $(WMOD_INFO_GET) '.mod_entry.compatibility.target_platform'
WMOD_TARGET_PUBLISHER != $(WMOD_INFO_GET) '.mod_entry.compatibility.target_publisher'
WMOD_TARGET_PATCH != $(WMOD_INFO_GET) '.mod_entry.compatibility.target_patch'

REV = HEAD
# version from an annotated tag or commit id
WMOD_VERSION != $(GIT) describe --abbrev=0 $(REV) 2>/dev/null || ( $(GIT) rev-parse $(REV) | $(CUT) -b-7 )

# Package name. Needed for Android packages
WOTB_PACKAGE_NAME = net.wargaming.wot.blitz
ifeq ($(WMOD_TARGET_PUBLISHER), lg)
	WOTB_PACKAGE_NAME = com.tanksblitz
endif

WMOD_TITLE != $(WMOD_INFO_GET) '.mod_entry.name'
# Mod title suitable for naming a package
WMOD_NAME != $(ECHO) $(WMOD_TITLE) | $(TR) '[:upper:] ' '[:lower:]-'
WMOD_PACKAGE_NAME = $(WMOD_NAME)_$(WMOD_VERSION)_$(WMOD_TARGET_PLATFORM:any=anyplat)_$(WMOD_TARGET_PUBLISHER:any=anypub)_$(WMOD_TARGET_PATCH:any=anypatch)
WMOD_PACKAGE_FORMAT = zip


# platform-specific game prefix, needed for making base directory for packages
# Default none - for anyplat mods
WOTB_PREFIX = .
ifeq ($(WMOD_TARGET_PLATFORM), steam)
	WOTB_PREFIX = Data
endif
ifeq ($(WMOD_TARGET_PLATFORM), android)
	WOTB_PREFIX = $(WOTB_PACKAGE_NAME)/files/packs
endif

# Default unset (impossible to determine where the game is installed)
WOTB_INSTALL_DIR = .
ifeq ($(WMOD_TARGET_PLATFORM), android)
	WOTB_INSTALL_DIR = /sdcard/Android/data
endif

# Default unset (impossible to determine where the game is installed)
WMOD_INSTALL_DIR = .
ifeq ($(WMOD_TARGET_PLATFORM), android)
	WMOD_INSTALL_DIR = $(WOTB_INSTALLDIR)/$(WOTB_PREFIX)
endif

### Directories
SRCDIR = src
BUILDDIR = build
MEDIADIR = public/media
DESCDIR = public/desc
DISTDIR = dist/general
TOOLSDIR = tools
SUPERPROJECTROOT != $(GIT) rev-parse --show-superproject-working-tree
PROJECTROOT != $(GIT) rev-parse --show-toplevel

BUILDPLATFORMDIR = $(BUILDDIR)/$(WMOD_TARGET_PLATFORM)/$(WOTB_PREFIX)

# Language for generating description. English by default.
# Can be overriden to make the description in another language.
WMOD_DESCRIPTION_LANGUAGE = en
DESCFILE = $(DESCDIR)/$(WMOD_DESCRIPTION_LANGUAGE).txt
