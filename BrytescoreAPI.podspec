#
# Be sure to run `pod lib lint BrytescoreAPI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BrytescoreAPI'
  s.version          = '1.2.0'
  s.summary          = 'Track user behavior and score their engagment with the Brytescore API.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
brytescore-ios is the open-source iOS SDK that connects your app with the Brytescore API. The Brytescore API allows you to track your users' behavior and score their engagement.
                       DESC

  s.homepage         = 'https://github.com/Brytecore/brytescore-ios'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'emilyemorehouse' => 'engineering@cuttlesoft.com' }
  s.source           = { :git => 'https://github.com/Brytecore/brytescore-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'BrytescoreAPI/**/*'

  # s.resource_bundles = {
  #   'BrytescoreAPI' => ['BrytescoreAPI/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
