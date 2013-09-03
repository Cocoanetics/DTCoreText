#!/bin/sh
set -e

xctool project DTCoreText.xcodeproj -scheme DemoApp build test -sdk iphonesimulator -arch i386
xctool project DTCoreText.xcodeproj -scheme MacUnitTest test
