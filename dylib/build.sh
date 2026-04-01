#!/bin/bash
SDK="/home/souza/theos/sdks/iPhoneOS16.5.sdk"
CLANG="clang"
OUT="KeyMaster.dylib"

$CLANG \
  -arch arm64 \
  -arch arm64e \
  -isysroot $SDK \
  -miphoneos-version-min=14.0 \
  -fobjc-arc \
  -shared \
  -framework UIKit \
  -framework Foundation \
  -o $OUT \
  Tweak.m

echo "Compilado: $OUT"
