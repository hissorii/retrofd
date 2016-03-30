LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := rfgui_no_ftm

NDK_PATH := /Users/hissorii/Development/android-ndk-r9b

LOCAL_C_INCLUDES := $(NDK_PATH)/platforms/android-18/arch-arm/usr/include $(NDK_PATH)/sources/android/support/include

# Add your application source files here...
LOCAL_SRC_FILES := rfgui_no_ftm.c

include $(BUILD_EXECUTABLE)

