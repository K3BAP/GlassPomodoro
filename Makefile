PROJECT := GlassPomodoro
SCHEME := GlassPomodoro
CONFIG := Debug
BUILD_DIR := build
DIST_DIR := dist
APP := $(BUILD_DIR)/Build/Products/$(CONFIG)/$(PROJECT).app
RELEASE_APP := $(BUILD_DIR)/Build/Products/Release/$(PROJECT).app

.PHONY: all generate build run icon release install clean

all: build

generate:
	xcodegen generate

build: generate
	xcodebuild -project $(PROJECT).xcodeproj -scheme $(SCHEME) -configuration $(CONFIG) -derivedDataPath $(BUILD_DIR) build

run: build
	open $(APP)

icon:
	./scripts/make_icon.sh

release: generate
	xcodebuild -project $(PROJECT).xcodeproj -scheme $(SCHEME) -configuration Release -derivedDataPath $(BUILD_DIR) build
	@mkdir -p $(DIST_DIR)
	@rm -rf "$(DIST_DIR)/$(PROJECT).app" "$(DIST_DIR)/$(PROJECT).zip"
	cp -R "$(RELEASE_APP)" "$(DIST_DIR)/$(PROJECT).app"
	cd $(DIST_DIR) && ditto -c -k --sequesterRsrc --keepParent "$(PROJECT).app" "$(PROJECT).zip"
	@echo "release: $(DIST_DIR)/$(PROJECT).app  ->  $(DIST_DIR)/$(PROJECT).zip"

install: release
	@rm -rf "/Applications/$(PROJECT).app"
	cp -R "$(RELEASE_APP)" "/Applications/$(PROJECT).app"
	@echo "install: /Applications/$(PROJECT).app"

clean:
	xcodebuild -project $(PROJECT).xcodeproj -scheme $(SCHEME) -configuration $(CONFIG) -derivedDataPath $(BUILD_DIR) clean
	rm -rf $(BUILD_DIR) $(DIST_DIR)
