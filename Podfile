platform :ios, '13.0'

target 'Pocket Contacts Pro' do
  use_frameworks!

  # Add CocoaPods dependencies here when needed.
  # Example: pod 'JPush'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
