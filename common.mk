# Common rootless configuration
THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
# Add to your Makefile
DEBUG = 1
STRIP = 0
# Use ldid instead of codesign (essential for jailbreak tweaks)
TARGET_CODESIGN = ldid

# Set default signing flags
TARGET_CODESIGN_FLAGS = -S

# For rootless, use entitlements
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
    TARGET_CODESIGN_FLAGS = -Sentitlements.rootless.xml
else
    TARGET_CODESIGN_FLAGS = -S
endif