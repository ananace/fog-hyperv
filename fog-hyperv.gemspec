# frozen_string_literal: true

require_relative 'lib/fog/hyperv/version'

Gem::Specification.new do |spec|
  spec.name          = 'fog-hyperv'
  spec.version       = Fog::Hyperv::VERSION
  spec.authors       = ['Alexander Olofsson']
  spec.email         = ['alexander.olofsson@liu.se']

  spec.summary       = 'Module for the `fog` gem to support Microsoft Hyper-V.'
  spec.description   = 'This library wraps Hyper-V in the `fog` concepts.'
  spec.homepage      = 'https://gitlab.liu.se/ITI/fog-hyperv'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*'] + %w[LICENSE README.md]
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency 'fog-core', '~> 2'
  spec.add_dependency 'fog-json', '~> 1'
  spec.add_dependency 'winrm', '~> 2'

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-mock'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-rake'
end
