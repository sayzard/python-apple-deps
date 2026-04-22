// swift-tools-version:5.9
// Package.swift — Swift Package Manager manifest for Python-aux xcframeworks.
//
// Checksums are intentionally left empty ("") — fill them in after uploading
// release assets:
//   swift package compute-checksum <name>.xcframework.zip
// or use the value reported by `xcodebuild -create-xcframework` output.

import PackageDescription

let tag = "v1.0.0"
let baseURL = "https://github.com/sayzard/python-apple-deps/releases/download/\(tag)"

func xcfw(_ name: String, checksum: String) -> Target {
    .binaryTarget(
        name: name,
        url: "\(baseURL)/\(name).xcframework.zip",
        checksum: checksum
    )
}

let package = Package(
    name: "Python-aux",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "crypto",              targets: ["crypto"]),
        .library(name: "freetype",            targets: ["freetype"]),
        .library(name: "harfbuzz",            targets: ["harfbuzz"]),
        .library(name: "libexslt",            targets: ["libexslt"]),
        .library(name: "libffi",              targets: ["libffi"]),
        .library(name: "libfftw3",            targets: ["libfftw3"]),
        .library(name: "libfftw3_threads",    targets: ["libfftw3_threads"]),
        .library(name: "libgdal",             targets: ["libgdal"]),
        .library(name: "libgeos",             targets: ["libgeos"]),
        .library(name: "libgeos_c",           targets: ["libgeos_c"]),
        .library(name: "libheif",             targets: ["libheif"]),
        .library(name: "libjpeg",             targets: ["libjpeg"]),
        .library(name: "liblzma",             targets: ["liblzma"]),
        .library(name: "libpng",              targets: ["libpng"]),
        .library(name: "libproj",             targets: ["libproj"]),
        .library(name: "libspatialindex",     targets: ["libspatialindex"]),
        .library(name: "libspatialindex_c",   targets: ["libspatialindex_c"]),
        .library(name: "libtiff",             targets: ["libtiff"]),
        .library(name: "libxslt",             targets: ["libxslt"]),
        .library(name: "libz",                targets: ["libz"]),
        .library(name: "libzmq",              targets: ["libzmq"]),
        .library(name: "openblas",            targets: ["openblas"]),
        .library(name: "openssl",             targets: ["openssl"]),
    ],
    targets: [
        // Checksums: run `swift package compute-checksum <name>.xcframework.zip`
        // after uploading release assets and paste the result here.
        xcfw("crypto",            checksum: "501de8653c549f4d44cbd278528e0f87a8775b93e8ba4656eeb1eb6f451ef188"),
        xcfw("freetype",          checksum: "b5324be9f72a2ba69f7c0c4c3ca8723e609fe82a35a2c2fc805a9d33fbe5b83a"),
        xcfw("harfbuzz",          checksum: "f96a3ff06682fc7d83666795f2c72624ad5b4f2d4348b65f34bfd8dffafbe39d"),
        xcfw("libexslt",          checksum: "251dc5054f950e631e5dc5a9b2d7bed2bdebb2431bf07029b85bfd0b560479a1"),
        xcfw("libffi",            checksum: "b704a3a974afb6fddded2e0c6a555ecdc00e70264f57ca485860dc5853fbcece"),
        xcfw("libfftw3",          checksum: "6f64290965d7c238833becbcab197a4f7152425075b85f3377ad48bd70974208"),
        xcfw("libfftw3_threads",  checksum: "3fadd1652592f7d1db38b9b88d1a163db7341b608f3620b641dc50336c996fc3"),
        xcfw("libgdal",           checksum: "ef2731b2a5a5c614e95ef4db945718b8eea5f8f16a7006c5e9cb156301964270"),
        xcfw("libgeos",           checksum: "3fe3d66a69d87247d345f8f3031a2957a1627afd0775b596d9bd668a50309da7"),
        xcfw("libgeos_c",         checksum: "c1b5cf1223faa9f5aca7a1af7fded8b9a304e155dc758bc307124b02047588b9"),
        xcfw("libheif",           checksum: "1b22871cdc15d15b8c5dd6e260d8c0dbfb3c53f7c200ff051814888fe24972c3"),
        xcfw("libjpeg",           checksum: "225a4cc8b1fe1c6f8c881de9972d759702f57c81cd575a0709a6f373ff2a3121"),
        xcfw("liblzma",           checksum: "23ca0a01622e2f0418f6ed599e17cee85625673e2d68b1ad5bd3477b27276cb9"),
        xcfw("libpng",            checksum: "085b0eff18d59c1c6819741fc7cbda57d04bbeaea4bf534c4ee4f44e8000d447"),
        xcfw("libproj",           checksum: "a78177c1454885fce745dda495805aaaa46a707077b10e28e44092f559caed02"),
        xcfw("libspatialindex",   checksum: "6210cfde2bc09da6784ee0f2d00dcfef4ec94d34370d279966384c06871f9cb1"),
        xcfw("libspatialindex_c", checksum: "1a3135c8f5a384d91859212dbb11db3eea75c45228c05017af5e1e9f3cfa5a5a"),
        xcfw("libtiff",           checksum: "91f706319a5e6f735d6551f5472946a8ce334c92c86a1e5c241021169445f727"),
        xcfw("libz",              checksum: "a65e894d997559702ad7594842423a4519416a8e5f12ef6fe81a042ee0c896af"),
        xcfw("libxslt",           checksum: "8d1a73cf9e75555ff44b82f788efba6bdf0afdab357cb844207af143781062d8"),
        xcfw("libzmq",            checksum: "82268b1a737d95403e9f04cb1395a86bac7be76387bcdc66cfe0a0829a095d77"),
        xcfw("openblas",          checksum: "02696cf58f54495832e69d8b43fc500c65d3cf7b6838ef94f505e25014e2d6f4"),
        xcfw("openssl",           checksum: "5bfb20696aa6ab25c7e90ad0f705bd1a62f5e591373a0b765c6da86d901bfef1"),
    ]
)
