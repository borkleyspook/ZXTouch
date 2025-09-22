# Common rootless configuration
THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
# Add to your Makefile
DEBUG = 1
STRIP = 0
TARGET_CODESIGN = ldid
# Set default signing flags
TARGET_CODESIGN_FLAGS = -S
# common.mk
export ROOT_PATH_NS = /var/jb
export TARGET_CFLAGS += -DROOT_PATH_NS='@"$(ROOT_PATH_NS)"'
# For rootless, use entitlements
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
    TARGET_CODESIGN_FLAGS = -S$(THEOS_PROJECT_DIR)/entitlements.rootless.xml
else
    TARGET_CODESIGN_FLAGS = -S
endif