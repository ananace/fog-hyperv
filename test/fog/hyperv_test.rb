require 'test_helper'

class Fog::HypervTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Fog::Hyperv::VERSION
  end
end
