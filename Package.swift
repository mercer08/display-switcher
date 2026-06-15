// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DisplaySwitcher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DisplaySwitcher", targets: ["DisplaySwitcherApp"])
    ],
    targets: [
        .executableTarget(
            name: "DisplaySwitcherApp",
            path: "Sources/DisplaySwitcherApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
