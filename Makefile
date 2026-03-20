APP_NAME = LlamaWatch
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR = /Applications

.PHONY: build install uninstall clean

build:
	@./build.sh

install: build
	@echo "Installing $(APP_NAME) to $(INSTALL_DIR)..."
	@cp -r $(APP_BUNDLE) $(INSTALL_DIR)/
	@echo "Done. You can launch $(APP_NAME) from Applications or Spotlight."

uninstall:
	@echo "Removing $(APP_NAME) from $(INSTALL_DIR)..."
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Done."

clean:
	@rm -rf $(BUILD_DIR)
	@echo "Build directory cleaned."
