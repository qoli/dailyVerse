# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'dailyVerse' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for dailyVerse
  
  # UI Labs
  pod 'NotificationBannerSwift'
  pod 'MMMaterialDesignSpinner'
  pod 'DynamicBlurView'
  pod 'Spring', :git => 'https://github.com/MengTo/Spring.git'

  # Network & base
  pod 'Alamofire'
  pod 'SwiftyJSON'
  
  # 統計
  pod 'Bugly'
  pod 'BaiduMobStatCodeless'
  
  pod 'SwiftDate'
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      if target.name == 'Spring'
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '4.2'
        end
      end
    end
  end

end

target 'Extension' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Extension
  pod 'Alamofire', '~> 4.5'

end
