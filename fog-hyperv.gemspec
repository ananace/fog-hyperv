require File.join(File.expand_path('lib', __dir__), 'fog/hyperv/version')

Gem::Specification.new do |spec|
  spec.name          = 'fog-hyperv'
  spec.version       = Fog::Hyperv::VERSION
  spec.authors       = ['Alexander Olofsson']
  spec.email         = ['alexander.olofsson@liu.se']

  spec.summary       = 'Module for the `fog` gem to support Microsoft Hyper-V.'
  spec.description   = 'This library wraps Hyper-V in the `fog` concepts.'
  spec.homepage      = 'https://github.com/ananace/fog-hyperv'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^test\/})

  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'fog-core', '>= 1.42', '< 3.0'
  spec.add_runtime_dependency 'fog-json', '~> 1'
  spec.add_runtime_dependency 'winrm', '~> 2'

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
end
