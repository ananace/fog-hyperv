# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fog/hyperv/version'

Gem::Specification.new do |spec|
  spec.name          = 'fog-hyperv'
  spec.version       = Fog::Hyperv::VERSION
  spec.authors       = ['Alexander Olofsson']
  spec.email         = ['alexander.olofsson@liu.se']

  spec.summary       = 'Module for the `fog` gem to support Microsoft Hyper-V.'
  spec.description   = 'This library wraps Hyper-V VM information in the `fog` concepts.'
  spec.homepage      = 'https://github.com/ace13/fog-hyperv'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^test\/})

  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'fog-core'
  spec.add_runtime_dependency 'fog-json'
  spec.add_runtime_dependency 'winrm'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
