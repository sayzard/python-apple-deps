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
        xcfw("crypto",            checksum: "4a8c45ea59fab23a9dded5edc63bcad2337df47b61c1e02b55f6ceb3b511a136"),
        xcfw("freetype",          checksum: "df33da9fa9b8387a27e908131289d02ab66891c7b954cf01d0c738905f3f1e3e"),
        xcfw("harfbuzz",          checksum: "dce6715f5a1246e672fdac06f0af66dd9b8fe201ce439720739938b4482c8d66"),
        xcfw("libexslt",          checksum: "731d27316d736941610ed8b8fec36ad7a16e888fe6a62159eb1969a1546fde53"),
        xcfw("libffi",            checksum: "fed92ee9f46b18db1c3caadc82fae8eeb2ec49ba7e5cb6a9105127b29f1d3e72"),
        xcfw("libfftw3",          checksum: "d12bf99c4e935e4165c622fd5a3255dada0b22d24da476cc18b744fba4a42de9"),
        xcfw("libfftw3_threads",  checksum: "b30c48af88314e04fdc5d0f32b75a8b96fc09e3a525aeff2e409a78d0ebec5f9"),
        xcfw("libgdal",           checksum: "2455664048f1c2fe29699d65db7c15164c9c4657a5747fd0a8358d47021b63e9"),
        xcfw("libgeos",           checksum: "8843790e6315ecd237cf7155be67613903b744abe97d39a98f91dfee04f1f65c"),
        xcfw("libgeos_c",         checksum: "231b0f40a6b44f2b57ad3a27b1a1c75e982d873f25d8e4aa7fa55b1657472014"),
        xcfw("libheif",           checksum: "22582349d8e19f84c6d37fde142ca49f4b0deb18d1fa360d45ce211be0c1ba17"),
        xcfw("libjpeg",           checksum: "7edd3c90198dbcdaaed6c01ea46860f1784cf290463962b97a2a0d5bfd4cd0c4"),
        xcfw("liblzma",           checksum: "2b85da09817deeff8986a671c8c9d40e3d8ec100231e6f98a7244f385238f736"),
        xcfw("libpng",            checksum: "383d2cacde2fd54325e0dd1c6fb61a3693d533a751450b4a4ee30916a91fe921"),
        xcfw("libproj",           checksum: "19b32457f8c0d3ab91ed1958864f89724478bb03a3911c616051b89b0855fa83"),
        xcfw("libspatialindex",   checksum: "35541109271115c9132dbdba4ef6a6d51c5a695b5d52577d93e2cd31eeccdf0a"),
        xcfw("libspatialindex_c", checksum: "5749222c072fedcc21e2f5a8a8a790e66f4d8819e9ab331e1bac88d244b185eb"),
        xcfw("libtiff",           checksum: "3726eca17d7c5091f7bd7596ed43c318ef7f1067c5d482c9dbfc505a1a1af337"),
        xcfw("libz",              checksum: "5c4771802bed7ff158b3222526b938180e2ef650d0d56b0f388361393b04f291"),
        xcfw("libxslt",           checksum: "c8f0de87ff488076d09f6152314986a8ec11a7572cfb4682349e4053e39fb5fd"),
        xcfw("libzmq",            checksum: "ad337558e4328c03d97f9d3b3af081059887318821c5ba0c82f5bd1972e44584"),
        xcfw("openblas",          checksum: "59e7367a22edff80403bfddbc59162429835ec1482051f0ea48105b6ac3117e3"),
        xcfw("openssl",           checksum: "cd1b7532d200fb5a5a5ee0de7c70f688eeadf390529080f20d5dd73af9f7c6ce"),
    ]
)
