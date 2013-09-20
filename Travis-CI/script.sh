#!/bin/sh
set -e

xctool project DTCoreText.xcodeproj -scheme DemoApp build test -sdk iphonesimulator

echo "result $?"

xctool project DTCoreText.xcodeproj -scheme MacUnitTest test

echo "result $?"
