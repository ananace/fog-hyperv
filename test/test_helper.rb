# frozen_string_literal: true

# Configure simplecov for coverage reporting
if ENV["COVERAGE"]
  require 'simplecov'

  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
  SimpleCov.skip_token('no-coverage')

  SimpleCov.start do
    add_filter "/test/"
  end
end

require 'minitest/reporters'
Minitest::Reporters.use! [
  Minitest::Reporters::ProgressReporter.new,
  Minitest::Reporters::JUnitReporter.new
]
require 'minitest/mock'
require 'minitest/autorun'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'fog/hyperv'
