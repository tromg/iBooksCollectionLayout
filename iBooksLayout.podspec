Pod::Spec.new do |s|
  s.name                  = "iBooksLayout"
  s.version               = "1.0.0"
  s.summary               = "Layout inspired by iBooks App"
  s.homepage              = "https://github.com/tromg/iBooksCollectionLayout"
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { "tromg" => "tromg1@gmail.com" }
  s.ios.deployment_target = '11.0'
  s.source                = { :git => "https://github.com/tromg/iBooksCollectionLayout.git", :tag => s.version.to_s }
  s.source_files          = 'iBooksCollectionLayout/Main*.{swift}'
  s.framework             = 'UIKit'
  s.requires_arc          = true
end
