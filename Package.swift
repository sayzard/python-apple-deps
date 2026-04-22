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
        xcfw("crypto",            checksum: "888cfcc611f476fe4d944ee34e794f34373381d08b068bd76db2f928c5235132"),
        xcfw("freetype",          checksum: "f033cc7538073a1b30d274d17456c76f474d3f4ad1326642afe360788fae2a9d"),
        xcfw("harfbuzz",          checksum: "111d0e96c53fe9dad919369be4ca3041efe2f69284378a6c0a7acd41c7f2931b"),
        xcfw("libexslt",          checksum: "733fdc6d8ecff233b86717e96bcb89fca4b6c711aca7763ee8236509839a35b9"),
        xcfw("libffi",            checksum: "c3f6c14e4116b356d7faa65bb44fd87a3424dd4a736c9512767e9b224d71af15"),
        xcfw("libfftw3",          checksum: "01b1938af35bcabddaa04cab0352059604e272b6ead4c579584a1f3c6295235a"),
        xcfw("libfftw3_threads",  checksum: "eb9e0432f92c4652ff111d310ac2af854b30bf602311412323f998e3a5295b65"),
        xcfw("libgdal",           checksum: "8ce283378b16d8711a355c258d53013dc5250968e7ffab1f746956bff03c2d67"),
        xcfw("libgeos",           checksum: "44d1aa7b5a097f99122aab4be7015e45da73978fc02d96989079f6f7c7034f57"),
        xcfw("libgeos_c",         checksum: "341247c9e0a3e869792c3486a38ac18adc0de9ed737fd62ded1e41d44d00c554"),
        xcfw("libheif",           checksum: "0256f6f47c9ca29cf937c5e5f144f3c37c478ccecd63cda7f48680555a42f2a3"),
        xcfw("libjpeg",           checksum: "dc06a8efad3afd167a485c0e07736163b16f61a7a3b881d14b713cb4d0a0d774"),
        xcfw("liblzma",           checksum: "bb7d2f730782a5b4306fcb994acef8757104a1389dd3373c84651c4aaa758a42"),
        xcfw("libpng",            checksum: "152df5130c8c6b8bc0d3ad89b0a4c6521875ddf6796c32efe14e6a9d21ec9272"),
        xcfw("libproj",           checksum: "4105e3249752f10f46166d95759cc615cd1f0398b738dacba1f3967e9c67c2ee"),
        xcfw("libspatialindex",   checksum: "614e36cbef242a0785e806a52339ca22f89998fef350988982d959ce9b008bd6"),
        xcfw("libspatialindex_c", checksum: "bb6102ea2a59d47fcfdf347141d849cddc201e1c279d656dc550d5655819896e"),
        xcfw("libtiff",           checksum: "ebc02ea154cd40b58ed5d450cc5bca76be852ff177482e789d7c5680e56f0c88"),
        xcfw("libz",              checksum: "aa7211c62178ddb839c1df9ef67bb1a8c0dd215b564915b72975dfb701556cde"),
        xcfw("libxslt",           checksum: "c6e94e8c47040a2c3f07d547f5c758be2a10fba9e88b41d6d0a867e955020759"),
        xcfw("libzmq",            checksum: "1e50411f7ed328bce727e68b0b80f6fa89776c1b6f33c2be633fcd401ed99247"),
        xcfw("openblas",          checksum: "419b6e8dc570f60e8a950bd281e454c609178a5f544db9e8d7d56feaba08d4e5"),
        xcfw("openssl",           checksum: "0806ced2bcec531c58539609b503ed9b2ea00c8fade0ad8f67157f44133c7a5b"),
    ]
)
