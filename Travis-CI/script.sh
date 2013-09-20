#!/bin/sh
set -e

xctool project DTCoreText.xcodeproj -scheme DemoApp build -sdk iphonesimulator
xctool project DTCoreText.xcodeproj -scheme DemoApp test -sdk iphonesimulator
xctool project DTCoreText.xcodeproj -scheme MacUnitTest test
