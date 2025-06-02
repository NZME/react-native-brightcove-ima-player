require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-brightcove-ima-player"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "15.0" }
  s.source       = { :git => "https://github.com/NZME/react-native-brightcove-ima-player.git", :tag => "v#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm}"
  s.exclude_files = ["ios/BrightcoveImaPlayerTest/**/*","ios/Pod*","ios/Pods/**/*"]

  s.dependency "React-Core"
  s.dependency "Brightcove-Player-IMA", '6.13.3'
  s.dependency 'Google-Mobile-Ads-SDK', '~> 11.4.0'
end
