# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yodlee_wrap/version'

Gem::Specification.new do |spec|
  spec.name          = "yodlee_wrap"
  spec.version       = YodleeWrap::VERSION
  spec.authors       = ["Shannon Byrne"]
  spec.email         = ["shannon@studentloangenius.com"]
  spec.summary       = "Yodlee API Client Gem for 2016 developer.yodlee gem"
  spec.description   = "Yodlee is a pain. This makes it a bit easier."
  spec.homepage      = ""
  spec.license       = "MIT"
  spec.files         = Dir["License.txt", "Readme.md", "lib/**/*"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"

  spec.add_runtime_dependency "faraday", '~> 0.9.1', '>= 0.9.1'
  spec.add_runtime_dependency "socksify", '~> 1.6.0', '>= 1.6.0'

# gem 'faraday', '0.9.0'
# gem 'socksify', '1.5.0'

  spec.required_ruby_version = '>= 1.9.3'
end
