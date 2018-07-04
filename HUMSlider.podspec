Pod::Spec.new do |s|
  s.name         = "HUMSlider"
  s.version      = '1.1.1'
  s.summary      = "HUMSlider"
  s.description  = <<-DESC
                   A UISlider with ticks and auto-saturating images.
                   DESC
  s.homepage     = "http://justhum.com"
  s.license      = 'MIT'
  s.author       = { "Ellen Shapiro" => "designatednerd@gmail.com" }
  s.source       = { :git => "https://github.com/just-hum/HUMSlider.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.1'
  s.ios.deployment_target = '8.1'
  s.requires_arc = true

  s.source_files = 'HUMSlider/HUMSlider.h', 'HUMSlider/HUMSlider.m'
end
