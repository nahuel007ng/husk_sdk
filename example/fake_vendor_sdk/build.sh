#!/usr/bin/env bash
# Builds the FAKE vendor SDK used by the husk_sdk example:
#   dist/AcmeWidgetSDK.xcframework  (static, iOS device arm64 + simulator arm64/x86_64)
#   dist/acme-widget-3.2.0.aar      (one Java class, no resources)
# Requires Xcode command line tools (iOS part) and a JDK (Android part).
# Usage: ./build.sh [ios|android|all]   (default: all)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
dist="$here/dist"
work="$here/.work"
version="3.2.0"
what="${1:-all}"

build_ios() {
  local name=AcmeWidgetSDK
  rm -rf "$work/ios" "$dist/$name.xcframework"
  mkdir -p "$work/ios" "$dist"
  # slice-name  sdk  target-triples...
  local slices=(
    "device iphoneos arm64-apple-ios13.0"
    "simulator iphonesimulator arm64-apple-ios13.0-simulator x86_64-apple-ios13.0-simulator"
  )
  local args=()
  for spec in "${slices[@]}"; do
    read -r slice sdk triples <<<"$spec"
    local sdkpath fw libs=()
    sdkpath="$(xcrun --sdk "$sdk" --show-sdk-path)"
    fw="$work/ios/$slice/$name.framework"
    mkdir -p "$fw/Modules/$name.swiftmodule"
    for triple in $triples; do
      # arm64-apple-ios13.0-simulator -> arm64-apple-ios-simulator
      local module_triple obj="$work/ios/$slice/$triple"
      module_triple="$(sed -E 's/ios[0-9.]+/ios/' <<<"$triple")"
      mkdir -p "$obj"
      xcrun --sdk "$sdk" swiftc -parse-as-library -module-name "$name" \
        -swift-version 5 -target "$triple" -sdk "$sdkpath" -O -whole-module-optimization \
        -enable-library-evolution \
        -emit-module-interface-path "$fw/Modules/$name.swiftmodule/$module_triple.swiftinterface" \
        -emit-module-path "$obj/$name.swiftmodule" \
        -c "$here/src/ios/$name.swift" -o "$obj/$name.o"
      xcrun --sdk "$sdk" libtool -static -o "$obj/lib$name.a" "$obj/$name.o"
      libs+=("$obj/lib$name.a")
    done
    xcrun lipo -create "${libs[@]}" -output "$fw/$name"
    cat >"$fw/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>$name</string>
  <key>CFBundleIdentifier</key><string>com.acme.widget.sdk</string>
  <key>CFBundleName</key><string>$name</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>MinimumOSVersion</key><string>13.0</string>
</dict>
</plist>
PLIST
    args+=(-framework "$fw")
  done
  xcodebuild -create-xcframework "${args[@]}" -output "$dist/$name.xcframework" >/dev/null
  echo "built $dist/$name.xcframework"
}

build_android() {
  local aar="$dist/acme-widget-$version.aar"
  rm -rf "$work/android" "$aar"
  mkdir -p "$work/android/classes" "$work/android/aar" "$dist"
  javac --release 8 -nowarn -d "$work/android/classes" \
    "$here/src/android/com/acme/widget/AcmeWidget.java" 2>/dev/null ||
    javac --release 11 -d "$work/android/classes" "$here/src/android/com/acme/widget/AcmeWidget.java"
  (cd "$work/android/classes" && jar cf "$work/android/aar/classes.jar" .)
  cp "$here/src/android/AndroidManifest.xml" "$work/android/aar/AndroidManifest.xml"
  : >"$work/android/aar/R.txt"
  (cd "$work/android/aar" && jar cfM "$aar" AndroidManifest.xml R.txt classes.jar)
  echo "built $aar"
}

case "$what" in
  ios) build_ios ;;
  android) build_android ;;
  all) build_ios; build_android ;;
  *) echo "usage: $0 [ios|android|all]" >&2; exit 2 ;;
esac
