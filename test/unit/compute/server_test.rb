# frozen_string_literal: true

require 'test_helper'

class UnitServerTest < Minitest::Test
  def setup
    Fog.mock!
    @client = Fog::Compute.new(provider: 'hyperv', hyperv_username: 'test')
  end

  def teardown
    Fog.unmock!
  end

  def test_vm_status
    server = @client.servers.first

    assert_equal 'mockvm1', server.name
    assert_equal :Off, server.state
    assert_equal :Ok, server.status.to_s.to_sym

    server = @client.servers[1]

    assert_equal 'mockvm2', server.name
    assert_equal :Running, server.state
    assert_equal :Ok, server.status.to_s.to_sym
  end
end
