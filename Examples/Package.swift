// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SocketExamples",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "MinimalRepro",
            dependencies: [
                .product(name: "Socket", package: "Socket")
            ],
            path: ".",
            sources: ["MinimalRepro.swift"]
        ),
        .executableTarget(
            name: "TestStaticInit",
            dependencies: [
                .product(name: "Socket", package: "Socket")
            ],
            path: ".",
            sources: ["TestStaticInit.swift"]
        ),
        .executableTarget(
            name: "TestFileEventsInit",
            dependencies: [
                .product(name: "Socket", package: "Socket")
            ],
            path: ".",
            sources: ["TestFileEventsInit.swift"]
        ),
        .executableTarget(
            name: "TestOverflowScenario",
            dependencies: [
                .product(name: "Socket", package: "Socket")
            ],
            path: ".",
            sources: ["TestOverflowScenario.swift"]
        ),
        .executableTarget(
            name: "TestDirectCrash",
            dependencies: [
                .product(name: "Socket", package: "Socket")
            ],
            path: ".",
            sources: ["TestDirectCrash.swift"]
        ),
        .executableTarget(
            name: "TestNumericCastIssue",
            dependencies: [
                .product(name: "Socket", package: "Socket")
            ],
            path: ".",
            sources: ["TestNumericCastIssue.swift"]
        ),
        .executableTarget(
            name: "TestSocketConnect",
            dependencies: [
                .product(name: "Socket", package: "Socket")
            ],
            path: ".",
            sources: ["TestSocketConnect.swift"]
        ),
        .executableTarget(
            name: "ReproduceCrash",
            dependencies: [
                .product(name: "Socket", package: "Socket")
            ],
            path: ".",
            sources: ["ReproduceCrash.swift"]
        )
    ]
)