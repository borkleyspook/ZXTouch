# Include common configuration
include common.mk
#export THEOS_DEVICE_IP = 192.168.0.3

SUBPROJECTS = appdelegate zxtouch-binary pccontrol

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/aggregate.mk

after-install::
	install.exec "chown -R mobile:mobile /var/mobile/Library/ZXTouch && killall -9 SpringBoard;"

