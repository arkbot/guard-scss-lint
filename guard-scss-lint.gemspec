# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'guard/scss-lint/version'

Gem::Specification.new do |spec|
  spec.name          = 'guard-scss-lint'
  spec.version       = Guard::ScssLintVersion.to_s
  spec.authors       = ['Adam Eberlin']
  spec.email         = ['ae@adameberlin.com']
  spec.summary       = 'Guard plugin for scss-lint'
  spec.description   = 'Automatically checks SCSS style with scss-lint when files are modified.'
  spec.homepage      = 'https://github.com/arkbot/guard-scss-lint'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.7'
  spec.add_development_dependency 'guard-rspec', '>= 4.2.3', '< 5.0'
  spec.add_development_dependency 'rubocop', '~> 0.20'
  spec.add_development_dependency 'ruby_gntp', '~> 0.3'

  spec.add_runtime_dependency 'guard', '~> 2.0'
  spec.add_runtime_dependency 'scss-lint', '~> 0.29.0'
end
