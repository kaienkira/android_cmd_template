#==============================================================================
#-*- FUNCTIONS -*-
#==============================================================================
define ECHO
	@printf "\033[;32m"; printf $1; printf "\033[0m\n"
endef

#==============================================================================
#-*- MAIN -*- 
#==============================================================================
ANDROID_SDK_BUILD_TOOL_DIR = \
	$(ANDROID_HOME)/build-tools/$(CFG_ANDROID_SDK_BUILD_TOOL)
ANDROID_SDK_PLATFORM_DIR = \
	$(ANDROID_HOME)/platforms/$(CFG_ANDROID_SDK_PLATFORM)
AAPT_ = $(ANDROID_SDK_BUILD_TOOL_DIR)/aapt

RESOURCE_DIR = res
BUILD_DIR = build
BUILD_GEN_DIR = build/gen
BUILD_BIN_DIR = build/bin
BUILD_GEN_SRC_DIR = $(BUILD_DIR)/gen/$(subst .,/,$(CFG_PACKAGE_NAME))

R_JAVA = $(BUILD_GEN_SRC_DIR)/R.java
CLASSES_DEX=$(BUILD_BIN_DIR)/classes.dex

.PHONY: build check-config clean

build: check-config $(CFG_FINAL_APK)

check-config:
ifndef ANDROID_HOME
	$(error ANDROID_HOME is undefined)
endif

$(CFG_FINAL_APK): $(CLASSES_DEX)

$(CLASSES_DEX): $(BUILD_BIN_DIR) $(R_JAVA) $(CFG_SOURCES)
	@$(call ECHO, "[build classes.dex ...]")

$(R_JAVA): $(BUILD_GEN_SRC_DIR) $(CFG_RESOURCES)
	@$(call ECHO, "[generate R.java ...]")
	@$(AAPT_) package -m \
	      -M AndroidManifest.xml \
		  -I $(ANDROID_SDK_PLATFORM_DIR)/android.jar \
		  -S $(RESOURCE_DIR) \
	      -J $(BUILD_GEN_DIR) \


$(BUILD_GEN_SRC_DIR) $(BUILD_BIN_DIR):
	@mkdir -p $@

clean:
	@rm -rf $(BUILD_GEN_DIR)
