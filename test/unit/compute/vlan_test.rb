# frozen_string_literal: true

require 'test_helper'

require 'fog/hyperv/compute/models/network_adapter_vlan'

class UnitVLANTest < Minitest::Test
  def test_vlanlist_render
    vlan_setting = Fog::Hyperv::Compute::NetworkAdapterVlan.new

    assert_equal '1,10,20,40', vlan_setting.send(:render_vlan_list, [1,10,20,40].shuffle)
    assert_equal '1-4', vlan_setting.send(:render_vlan_list, [1,2,3,4].shuffle)
    assert_equal '1,3-8,10', vlan_setting.send(:render_vlan_list, [1,*(3..8),10].shuffle)
    assert_equal '1,10-20,22-30', vlan_setting.send(:render_vlan_list, [1,*(10..20),*(22..30)].shuffle)
    assert_equal '1,10-30', vlan_setting.send(:render_vlan_list, [1,*(10..20),*(21..30)].shuffle)
    assert_equal '1-4096', vlan_setting.send(:render_vlan_list, (1..4096).to_a.shuffle)
  end
end

