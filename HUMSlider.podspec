Pod::Spec.new do |s|
  s.name         = "HUMSlider"
  s.version      = '1.0.0'
  s.summary      = "HUMSlider"
  s.description  = <<-DESC
                   A UISlider with ticks and auto-saturating images. 
                   DESC
  s.homepage     = "http://www.designatednerd.com"
  s.license      = 'MIT'
  s.author       = { "Ellen Shapiro" => "designatednerd@gmail.com" }
  s.source       = { :git => "https://github.com/just-hum/HUMSlider.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Library'
end