# Include common configuration
include ../common.mk
#export THEOS_DEVICE_IP = 192.168.101.245

include $(THEOS)/makefiles/common.mk

TOOL_NAME = zxtouchb

zxtouchb_FILES = main.mm
zxtouchb_FRAMEWORKS = CoreFoundation UIKit CoreGraphics
zxtouchb_CFLAGS = -fobjc-arc -Wno-error -Wno-module-import-in-extern-c -O2 -s -DNDEBUG
zxtouchb_CODESIGN_FLAGS = -S$(THEOS_PROJECT_DIR)/entitlements.rootless.xml

include $(THEOS_MAKE_PATH)/tool.mk
