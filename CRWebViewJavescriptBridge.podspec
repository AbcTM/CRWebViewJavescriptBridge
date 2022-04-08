Pod::Spec.new do |s|
  s.name             = 'CRWebViewJavescriptBridge'
  s.version          = '0.1.0'
  s.summary          = '用于图形化编程webview与原生桥接'
  s.description      = <<-DESC
  用于图形化编程webview与原生桥接
                       DESC

  s.homepage         = 'https://github.com/AbcTM/CRWebViewJavescriptBridge'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tianlinchun' => 'tianlinchun@keyirobot.com' }
  s.source           = { :git => 'https://github.com/AbcTM/CRWebViewJavescriptBridgegit', :tag => s.version.to_s }

  s.swift_version = '5.1'
  s.ios.deployment_target = '10.0'

  s.source_files = 'CRWebViewJavescriptBridge/*.{h,m}'

  s.libraries = 'c', 'c++'
  s.frameworks = 'UIKit', 'Foundation', 'WebKit'
  s.requires_arc = true
end
