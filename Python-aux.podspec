Pod::Spec.new do |s|
  s.name         = "Python-aux"
  s.version      = "2.0.0"
  s.summary      = "Rebuilt native C-extension xcframeworks for iOS/macOS Python."
  s.description  = <<-DESC
    Drop-in replacement for holzschu/Python-aux with updated packages and arm64
    Simulator support. Provides 21 xcframeworks covering crypto, image formats,
    geospatial, numerical, and messaging libraries.
  DESC
  s.homepage     = "https://github.com/sayzard/python-apple-deps"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = "Python-aux Contributors"
  s.platforms    = { :ios => "16.0", :osx => "13.0" }
  s.source       = {
    :http => "https://github.com/sayzard/python-apple-deps/releases/download/v1.0.0/all-xcframeworks.zip"
  }

  # One subspec per xcframework.
  # Consumers declare a dependency on the individual subspecs they need, e.g.:
  #   pod 'Python-aux/libzmq'
  #   pod 'Python-aux/openblas'
  [
    "crypto",
    "freetype",
    "harfbuzz",
    "libexslt",
    "libffi",
    "libfftw3",
    "libfftw3_threads",
    "libgdal",
    "libgeos",
    "libgeos_c",
    "libjpeg",
    "liblzma",
    "libpng",
    "libproj",
    "libspatialindex",
    "libspatialindex_c",
    "libtiff",
    "libxslt",
    "libzmq",
    "openblas",
    "openssl",
  ].each do |fw_name|
    s.subspec fw_name do |sp|
      sp.vendored_frameworks = "#{fw_name}.xcframework"
    end
  end
end
