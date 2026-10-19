.PHONY: bootstrap pods build test ci open clean help

SCHEME ?= Pocket Contacts Pro
WORKSPACE ?= Pocket Contacts Pro.xcworkspace
DESTINATION ?= platform=iOS Simulator,name=iPhone 16,OS=latest

help:
	@echo "Targets:"
	@echo "  make bootstrap  - install gems + pods"
	@echo "  make pods       - pod install"
	@echo "  make build      - unsigned Simulator build"
	@echo "  make test       - unit tests"
	@echo "  make ci         - pods + build + test (scripts/ci_build.sh)"
	@echo "  make open       - open Xcode workspace"
	@echo "  make clean      - remove DerivedData / artifacts"

bootstrap:
	./scripts/bootstrap.sh

pods:
	bundle exec pod install

build:
	mkdir -p artifacts build
	xcodebuild \
	  -workspace "$(WORKSPACE)" \
	  -scheme "$(SCHEME)" \
	  -configuration Debug \
	  -destination "$(DESTINATION)" \
	  -derivedDataPath build/DerivedData \
	  CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES \
	  build

test:
	mkdir -p artifacts
	xcodebuild \
	  -workspace "$(WORKSPACE)" \
	  -scheme "$(SCHEME)" \
	  -configuration Debug \
	  -destination "$(DESTINATION)" \
	  -derivedDataPath build/DerivedData \
	  -resultBundlePath artifacts/PocketContactsPro.xcresult \
	  -enableCodeCoverage YES \
	  CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES \
	  test

ci:
	./scripts/ci_build.sh

open:
	open "$(WORKSPACE)"

clean:
	rm -rf build DerivedData artifacts fastlane/test_output fastlane/logs Pods
