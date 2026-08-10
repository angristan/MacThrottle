.PHONY: dev build kill open clean

SHELL := /bin/bash

APP_NAME := MacThrottle
BUILD_DIR := .build
APP_PATH := $(BUILD_DIR)/Build/Products/Debug/$(APP_NAME).app

dev: build kill open

build:
	@echo "Building $(APP_NAME)..."
	@set -o pipefail; xcodebuild -scheme $(APP_NAME) -configuration Debug -derivedDataPath $(BUILD_DIR) build 2>&1 | tail -5

kill:
	@pkill -x $(APP_NAME) 2>/dev/null || true

open:
	@echo "Opening $(APP_NAME)..."
	@open "$(APP_PATH)"

clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@xcodebuild clean -scheme $(APP_NAME) -quiet
