#!/bin/sh
set -e
xctool -project DTCoreText.xcodeproj -scheme DemoApp build test -sdk iphonesimulator6.1 -arch i386 ONLY_ACTIVE_ARCH=NO
xctool -project DTCoreText.xcodeproj -scheme "Mac Framework" test -arch x86_64 ONLY_ACTIVE_ARCH=NO
xctool -project DTCoreText.xcodeproj -scheme "Documentation"
