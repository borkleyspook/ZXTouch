# Common rootless configuration
THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0

# Debug settings
DEBUG = 1
STRIP = 0

# common.mk
export ROOT_PATH_NS = /var/jb
export TARGET_CFLAGS += -DROOT_PATH_NS='@"$(ROOT_PATH_NS)"' -fobjc-arc

# Signing configuration - USE WRAPPER since ldid is broken
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
    # Use wrapper script to translate ldid flags to codesign
    TARGET_CODESIGN = $(THEOS_PROJECT_DIR)/ldid-wrapper.sh
    TARGET_CODESIGN_FLAGS = -S$(THEOS_PROJECT_DIR)/entitlements.rootless.xml
else
    # For non-rootless, use ldid directly (if it works) or codesign
    TARGET_CODESIGN = codesign
    TARGET_CODESIGN_FLAGS = -f -s - --entitlements
endif