#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint acme_widget.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'acme_widget'
  s.version          = '0.0.1'
  s.summary          = 'Example plugin for husk_sdk.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'acme_widget/Sources/acme_widget/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'acme_widget_privacy' => ['acme_widget/Sources/acme_widget/PrivacyInfo.xcprivacy']}

  # BEGIN husk_sdk: generated from husk.yaml, do not edit. Regenerate with `dart run husk_sdk generate`.
  # Links AcmeWidgetSDK.xcframework when acme_widget/husk_vendor/ holds it (copied there
  # by `dart run husk_sdk link`, which also reads $ACME_WIDGET_SDK_DIR) and
  # compiles the AcmeWidgetSDKHusk stub otherwise. HUSK_SDK_DISABLE=1 forces the
  # stub. Run `pod install` after linking or unlinking so CocoaPods re-reads
  # this file.
  husk_off = !ENV['HUSK_SDK_DISABLE'].to_s.empty? && ENV['HUSK_SDK_DISABLE'] != '0'
  husk_sdk = 'acme_widget/husk_vendor/AcmeWidgetSDK.xcframework'
  husk_sdk = nil if husk_off || !File.exist?(File.join(File.dirname(File.expand_path(__FILE__)), husk_sdk, 'Info.plist'))
  s.source_files = Array(s.attributes_hash['source_files']) + ['acme_widget/Sources/AcmeWidgetSDKHusk/**/*.swift']
  if husk_sdk
    s.vendored_frameworks = husk_sdk
    s.pod_target_xcconfig = (s.attributes_hash['pod_target_xcconfig'] || {}).merge(
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) HUSK_ACMEWIDGETSDK'
    )
  end
  # END husk_sdk
end
