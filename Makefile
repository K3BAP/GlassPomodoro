PROJECT := GlassPomodoro
SCHEME := GlassPomodoro
CONFIG := Debug
BUILD_DIR := build
APP := $(BUILD_DIR)/Build/Products/$(CONFIG)/$(PROJECT).app

.PHONY: all generate build run clean

all: build

generate:
	xcodegen generate

build: generate
	xcodebuild -project $(PROJECT).xcodeproj -scheme $(SCHEME) -configuration $(CONFIG) -derivedDataPath $(BUILD_DIR) build

run: build
	open $(APP)

clean:
	xcodebuild -project $(PROJECT).xcodeproj -scheme $(SCHEME) -configuration $(CONFIG) -derivedDataPath $(BUILD_DIR) clean
	rm -rf $(BUILD_DIR)
