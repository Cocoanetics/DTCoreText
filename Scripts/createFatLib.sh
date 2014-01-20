#!/bin/sh
XCODE_BUILD_DIR="../build"
RELEASE_DIR="./release"

set -e
set -x

mkdir -p $RELEASE_DIR
mkdir -p $XCODE_BUILD_DIR

mkdir -p $RELEASE_DIR/Headers/DTCoreText
mkdir -p $RELEASE_DIR/Headers/DTFoundation

xcodebuild -project ../DTCoreText.xcodeproj -target "Static Library" -sdk iphoneos "ARCHS=armv6 armv7" clean build
xcodebuild -project ../DTCoreText.xcodeproj -target "Static Library" -sdk iphonesimulator "ARCHS=i386 x86_64" "VALID_ARCHS=i386 x86_64" clean build
lipo -output release/DTCoreText-iOS.a -create $XCODE_BUILD_DIR/Release-iphoneos/libDTCoreText.a $XCODE_BUILD_DIR/Release-iphonesimulator/libDTCoreText.a

cp ../Core/Source/*.h $RELEASE_DIR/DTCoreText/
cp ../Core/Source/iOS/*.h $RELEASE_DIR/DTCoreText/
cp ../Externals/DTFoundation/Core/Source/*.h $RELEASE_DIR/DTFoundation/

#./updateAPI.sh
#cp ../CHANGES ../release/
