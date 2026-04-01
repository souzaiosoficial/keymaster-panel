# Makefile — KeyMaster Dylib
# Compilar com: make (requer Theos instalado)

ARCHS       = arm64 arm64e
TARGET      = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME  = KeyMaster

KeyMaster_FILES          = Tweak.xm
KeyMaster_FRAMEWORKS     = UIKit Foundation
KeyMaster_PRIVATE_FRAMEWORKS =
KeyMaster_CFLAGS         = -fobjc-arc
KeyMaster_LDFLAGS        =

include $(THEOS_MAKE_PATH)/tweak.mk
