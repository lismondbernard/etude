// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EtudeKit",
    // EtudeKit is platform-agnostic (no UIKit/SwiftUI). These platforms exist only
    // so the same package can be consumed by the iOS app target; the engine and its
    // tests run on any of them, and `swift test` runs on the host with no simulator.
    platforms: [
        .macOS(.v13),
        .iOS(.v17),
    ],
    products: [
        .library(name: "EtudeKit", targets: ["EtudeKit"]),
    ],
    targets: [
        .target(
            name: "EtudeKit",
            path: "Sources/EtudeKit"
        ),
        .testTarget(
            name: "EtudeKitTests",
            dependencies: ["EtudeKit"],
            path: "Tests/EtudeKitTests",
            // Golden .mid fixtures are compared byte-for-byte against emitted output.
            // They ship as bundle resources so tests read them via Bundle.module.
            resources: [
                .copy("Golden/Fixtures"),
            ]
        ),
    ]
)
