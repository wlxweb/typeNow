// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "typeNow",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "typeNow", targets: ["typeNow"])
    ],
    targets: [
        .executableTarget(
            name: "typeNow"
        )
    ]
)
