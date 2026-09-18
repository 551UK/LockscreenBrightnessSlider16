# Rootless iOS 16 Dopamine build configuration
ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:16.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LockscreenBrightnessSlider16
LockscreenBrightnessSlider16_FILES = Tweak.xm
LockscreenBrightnessSlider16_FRAMEWORKS = UIKit Foundation QuartzCore
LockscreenBrightnessSlider16_CFLAGS = -fobjc-arc -Wall -Wextra -Wno-unused-parameter

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
