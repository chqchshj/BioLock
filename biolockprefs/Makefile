TARGET = iphone:latest:15.0

include $(THEOS)/makefiles/common.mk
ARCHS = arm64 arm64e

BUNDLE_NAME = biolockprefs

biolockprefs_FILES = BLPRootListController.m
biolockprefs_FRAMEWORKS = UIKit CoreFoundation MobileCoreServices
biolockprefs_EXTRA_FRAMEWORKS = AltList
biolockprefs_PRIVATE_FRAMEWORKS = Preferences
biolockprefs_INSTALL_PATH = /Library/PreferenceBundles
biolockprefs_CFLAGS = -fobjc-arc -I.
biolockprefs_LDFLAGS = -F$(THEOS)/sdks/iPhoneOS16.5.sdk/System/Library/Frameworks

include $(THEOS_MAKE_PATH)/bundle.mk
