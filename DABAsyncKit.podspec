#
# Be sure to run `pod lib lint AsyncKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DABAsyncKit'
	s.module_name      = 'AsyncKit'
  s.version          = '1.0.0'
  s.summary          = 'Tools to make async code more pleasent in Swift.'

  s.homepage         = 'https://github.com/davbeck/AsyncKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'davbeck' => 'code@davidbeck.co' }
  s.source           = { :git => 'https://github.com/davbeck/AsyncKit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/davbeck'

  s.swift_version = '4.0'
  s.ios.deployment_target = '11.0'

  s.source_files = 'AsyncKit/**/*'
end
