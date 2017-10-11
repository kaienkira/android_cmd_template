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
AAPT = $(ANDROID_SDK_BUILD_TOOL_DIR)/aapt
ANDROID_JAR = $(ANDROID_SDK_PLATFORM_DIR)/android.jar
JACK_JAR = $(ANDROID_SDK_BUILD_TOOL_DIR)/jack.jar

RESOURCE_DIR = res
KEY_DIR = key
BUILD_DIR = build
BUILD_GEN_DIR = build/gen
BUILD_BIN_DIR = build/bin
BUILD_GEN_SRC_DIR = $(BUILD_DIR)/gen/$(subst .,/,$(CFG_PACKAGE_NAME))

R_JAVA = $(BUILD_GEN_SRC_DIR)/R.java
CLASSES_DEX=$(BUILD_BIN_DIR)/classes.dex
UNALIGNED_APK=$(BUILD_BIN_DIR)/$(CFG_APK_NAME)-unaligned.apk
UNSIGNED_APK=$(BUILD_BIN_DIR)/$(CFG_APK_NAME)-unsigned.apk
FINAL_APK=$(BUILD_BIN_DIR)/$(CFG_APK_NAME).apk

.PHONY: build check-config create-dir clean

build: check-config create-dir $(FINAL_APK)

check-config:
ifndef ANDROID_HOME
	$(error ANDROID_HOME is undefined)
endif

create-dir:
	@mkdir -p $(BUILD_GEN_SRC_DIR) 
	@mkdir -p $(BUILD_BIN_DIR)

$(FINAL_APK): $(UNSIGNED_APK)
	@$(call ECHO, "[build final apk ...]")
	@apksigner sign --ks $(KEY_DIR)/android.keystore \
		--ks-pass file:$(KEY_DIR)/keystore.password \
		--key-pass file:$(KEY_DIR)/key.password \
		--out $(FINAL_APK) $(UNSIGNED_APK)

$(UNSIGNED_APK): $(UNALIGNED_APK)
	@$(call ECHO, "[build unsigned apk ...]")
	@zipalign -v -f -p 4 $(UNALIGNED_APK) $(UNSIGNED_APK)

$(UNALIGNED_APK): AndroidManifest.xml $(CLASSES_DEX) $(CFG_RESOURCES)
	@$(call ECHO, "[build unaligned apk ...]")
	@$(AAPT) package -M AndroidManifest.xml \
		-I $(ANDROID_JAR) -S $(RESOURCE_DIR) \
		-F $(UNALIGNED_APK) -f
	@cd $(BUILD_BIN_DIR) && $(AAPT) add $(abspath $(UNALIGNED_APK)) classes.dex

$(CLASSES_DEX): $(CFG_SOURCES) $(R_JAVA)
	@$(call ECHO, "[build classes.dex ...]")
	@java -jar $(JACK_JAR) --classpath $(ANDROID_JAR) \
		--output-dex $(BUILD_BIN_DIR) \
		$(CFG_SOURCES) $(R_JAVA)

$(R_JAVA): AndroidManifest.xml $(CFG_RESOURCES)
	@$(call ECHO, "[generate R.java ...]")
	@$(AAPT) package -M AndroidManifest.xml \
		  -I $(ANDROID_JAR) -S $(RESOURCE_DIR) \
		  -J $(BUILD_GEN_DIR) -m

clean:
	@$(call ECHO, "[clean build dir ...]")
	@rm -rf $(BUILD_GEN_DIR)
	@rm -rf $(BUILD_BIN_DIR)
