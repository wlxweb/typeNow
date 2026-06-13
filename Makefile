.PHONY: build run clean app open icon

build:
	swift build -c release

run:
	swift run

clean:
	swift package clean

icon:
	./scripts/generate-icon.sh

app: build icon
	mkdir -p typeNow.app/Contents/MacOS
	mkdir -p typeNow.app/Contents/Resources
	cp .build/release/typeNow typeNow.app/Contents/MacOS/
	cp Resources/Info.plist typeNow.app/Contents/Info.plist
	cp Resources/icon.icns typeNow.app/Contents/Resources/
	@echo "Created typeNow.app"

open:
	open Package.swift
