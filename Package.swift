// swift-tools-version:5.9
// Package.swift — Swift Package Manager manifest for Python-aux xcframeworks.
//
// Checksums are intentionally left empty ("") — fill them in after uploading
// release assets:
//   swift package compute-checksum <name>.xcframework.zip
// or use the value reported by `xcodebuild -create-xcframework` output.

import PackageDescription

let tag = "v1.1.0"
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
        xcfw("crypto",            checksum: ""),
        xcfw("freetype",          checksum: ""),
        xcfw("harfbuzz",          checksum: ""),
        xcfw("libexslt",          checksum: ""),
        xcfw("libffi",            checksum: ""),
        xcfw("libfftw3",          checksum: ""),
        xcfw("libfftw3_threads",  checksum: ""),
        xcfw("libgdal",           checksum: ""),
        xcfw("libgeos",           checksum: ""),
        xcfw("libgeos_c",         checksum: ""),
        xcfw("libheif",           checksum: ""),
        xcfw("libjpeg",           checksum: ""),
        xcfw("liblzma",           checksum: ""),
        xcfw("libpng",            checksum: ""),
        xcfw("libproj",           checksum: ""),
        xcfw("libspatialindex",   checksum: ""),
        xcfw("libspatialindex_c", checksum: ""),
        xcfw("libtiff",           checksum: ""),
        xcfw("libz",              checksum: ""),
        xcfw("libxslt",           checksum: ""),
        xcfw("libzmq",            checksum: ""),
        xcfw("openblas",          checksum: ""),
        xcfw("openssl",           checksum: ""),
    ]
)
