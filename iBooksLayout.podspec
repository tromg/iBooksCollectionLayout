Pod::Spec.new do |s|
  s.name                  = "iBooksLayout"
  s.version               = "1.0.0"
  s.summary               = "Layout inspired by iBooks App"
  s.homepage              = "https://github.com/tromg/iBooksCollectionLayout"
  s.license               = { :type => 'Apache License, Version 2.0', :text => <<-LICENSE
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    LICENSE
  }
  s.author                = { "tromg" => "tromg1@gmail.com" }
  s.ios.deployment_target = '11.0'
  s.source                = { :git => "https://github.com/tromg/iBooksCollectionLayout.git", :tag => s.version.to_s }
  s.source_files          = 'iBooksCollectionLayout/Main/*.{swift}'
  s.framework             = 'UIKit'
  s.requires_arc          = true
  s.swift_versions	  = "5.1"
end
