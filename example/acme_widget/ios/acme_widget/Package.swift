// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "acme_widget",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "acme-widget", targets: ["acme_widget"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "acme_widget",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // If your plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)

// BEGIN husk_sdk: generated from husk.yaml, do not edit. Regenerate with `dart run husk_sdk generate`.
// Links AcmeWidgetSDK.xcframework when it is found and builds the AcmeWidgetSDKHusk
// stub target otherwise. Looked up in this order:
//   1. $ACME_WIDGET_SDK_DIR/AcmeWidgetSDK.xcframework (absolute, or relative to
//      this directory)
//   2. husk_vendor/AcmeWidgetSDK.xcframework, filled by `dart run husk_sdk link`
// HUSK_SDK_DISABLE=1 forces the stub. SwiftPM caches the evaluated manifest
// by its text and the environment, not by the files it looks at: see
// doc/traps.md in husk_sdk when a build does not notice a change.
import Foundation

let huskAcmeWidgetSDKPath: String? = {
    let env = Context.environment
    if let off = env["HUSK_SDK_DISABLE"], !off.isEmpty, off != "0" { return nil }
    let root = URL(fileURLWithPath: Context.packageDirectory).standardizedFileURL
    var candidates: [URL] = []
    if let dir = env["ACME_WIDGET_SDK_DIR"], !dir.isEmpty {
        let base = URL(fileURLWithPath: dir, relativeTo: root)
        candidates.append(base.appendingPathComponent("AcmeWidgetSDK.xcframework").standardizedFileURL)
    }
    candidates.append(root.appendingPathComponent("husk_vendor/AcmeWidgetSDK.xcframework"))
    let found = candidates.first {
        FileManager.default.fileExists(atPath: $0.appendingPathComponent("Info.plist").path)
    }
    guard let found else { return nil }
    // binaryTarget paths must be relative to the package root.
    let from = root.pathComponents
    let to = found.pathComponents
    var common = 0
    while common < min(from.count, to.count) && from[common] == to[common] { common += 1 }
    return (Array(repeating: "..", count: from.count - common) + to[common...]).joined(separator: "/")
}()

package.targets.append(
    .target(
        name: "AcmeWidgetSDKHusk",
        dependencies: huskAcmeWidgetSDKPath == nil ? [] : [.target(name: "AcmeWidgetSDK")],
        path: "Sources/AcmeWidgetSDKHusk",
        swiftSettings: huskAcmeWidgetSDKPath == nil ? [] : [.define("HUSK_ACMEWIDGETSDK")]
    )
)
if let path = huskAcmeWidgetSDKPath {
    package.targets.append(.binaryTarget(name: "AcmeWidgetSDK", path: path))
}
for target in package.targets where target.name == "acme_widget" {
    target.dependencies.append(.target(name: "AcmeWidgetSDKHusk"))
    if huskAcmeWidgetSDKPath != nil {
        target.dependencies.append(.target(name: "AcmeWidgetSDK"))
        target.swiftSettings = (target.swiftSettings ?? []) + [.define("HUSK_ACMEWIDGETSDK")]
    }
}
// END husk_sdk
