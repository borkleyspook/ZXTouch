# Common rootless configuration
THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
DEBUG = 1
STRIP = 0

# Use macOS codesign instead of ldid
TARGET_CODESIGN = codesign

# Define rootless macro for source code
export ROOT_PATH_NS = /var/jb
export TARGET_CFLAGS += -DROOT_PATH_NS='@"$(ROOT_PATH_NS)"'

# For rootless, use entitlements
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
    TARGET_CODESIGN_FLAGS = --force --sign - --entitlements $(THEOS_PROJECT_DIR)/entitlements.rootless.xml
else
    TARGET_CODESIGN_FLAGS = --force --sign -
endif

# Component-specific flags (redundant but safe)
zxtouchb_CODESIGN_FLAGS = --force --sign - --entitlements $(THEOS_PROJECT_DIR)/entitlements.rootless.xml
appdelegate_CODESIGN_FLAGS = --force --sign - --entitlements $(THEOS_PROJECT_DIR)/entitlements.rootless.xml
pccontrol_CODESIGN_FLAGS = --force --sign - --entitlements $(THEOS_PROJECT_DIR)/entitlements.rootless.xml