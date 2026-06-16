TARGET = iphone:latest:15.0

include $(THEOS)/makefiles/common.mk
ARCHS = arm64 arm64e

BUNDLE_NAME = biolockprefs

biolockprefs_FILES = BLPRootListController.m BLPAppListController.m
biolockprefs_FRAMEWORKS = UIKit CoreFoundation MobileCoreServices
biolockprefs_PRIVATE_FRAMEWORKS = Preferences
biolockprefs_INSTALL_PATH = /Library/PreferenceBundles
biolockprefs_CFLAGS = -fobjc-arc -I.

include $(THEOS_MAKE_PATH)/bundle.mk
