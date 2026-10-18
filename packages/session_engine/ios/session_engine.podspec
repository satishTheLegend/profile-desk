# Local path dependency. Public distribution metadata has not been assigned.
Pod::Spec.new do |s|
  s.name             = 'session_engine'
  s.version          = '0.0.1'
  s.summary          = 'Native named-profile session ownership for Profile Desk.'
  s.description      = <<-DESC
Manages isolated WKWebsiteDataStore profiles, transactional local cleanup,
privacy covers, OS authentication, and owned file transfers for the Flutter app.
                       DESC
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Local project'
  s.source           = { :path => '.' }
  s.source_files = 'session_engine/Sources/session_engine/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '17.0'
  s.libraries = 'sqlite3'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {
    'session_engine_privacy' => ['session_engine/Sources/session_engine/PrivacyInfo.xcprivacy'],
    'session_engine_layout' => ['../layout/workspace_layout.js']
  }
end
