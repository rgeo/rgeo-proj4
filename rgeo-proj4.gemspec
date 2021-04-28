require_relative "./lib/rgeo/proj4/version"

Gem::Specification.new do |spec|
  spec.name          = "rgeo-proj4"
  spec.version       = RGeo::Proj4::VERSION
  spec.authors       = ["Tee Parham, Daniel Azuma"]
  spec.email         = ["parhameter@gmail.com, dazuma@gmail.com"]

  spec.summary       = "Proj4 extension for rgeo."
  spec.description   = "Proj4 extension for rgeo."
  spec.homepage      = "https://github.com/rgeo/rgeo-proj4"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.files         = Dir["lib/**/*.rb", "ext/**/*.{rb,c,h}", "LICENSE.txt"]
  spec.extensions    = ["ext/proj4_c_impl/extconf.rb"]

  spec.add_dependency "rgeo", "~> 2.0"

  spec.add_development_dependency "minitest", "~> 5.14"
  spec.add_development_dependency "pry-byebug", "~> 3.9.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-compiler", "~> 1.0"
  spec.add_development_dependency "rubocop", "~> 1.8.1"
end
