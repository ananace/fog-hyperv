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

  def test_update
    vlan_setting = Fog::Hyperv::Compute::NetworkAdapterVlan.new(
      parent_adapter: Object.new,
      service: Object.new,

      operation_mode: :Untagged,
      private_vlan_mode: :Isolated,

      access_vlan_id: 1,
      native_vlan_id: 2,
      primary_vlan_id: 3,
      secondary_vlan_id: 4,

      allowed_vlan_id_list: [1,2,3],
      secondary_vlan_id_list: [1,2,3]
    )
    assert vlan_setting.instance_variable_get :@old

    refute vlan_setting.dirty?
    assert_equal({}, vlan_setting.send(:build_changelist))

    vlan_setting.operation_mode = :Access
    assert_equal({ access: true, access_vlan_id: 1 }, vlan_setting.send(:build_changelist))
    vlan_setting.instance_variable_set :@old, vlan_setting.dup

    vlan_setting.access_vlan_id = 2
    assert_equal({ access: true, access_vlan_id: 2 }, vlan_setting.send(:build_changelist))
    vlan_setting.instance_variable_set :@old, vlan_setting.dup

    vlan_setting.operation_mode = :Trunk
    assert_equal({ trunk: true, native_vlan_id: 2, allowed_vlan_id_list: '1-3' }, vlan_setting.send(:build_changelist))
    vlan_setting.instance_variable_set :@old, vlan_setting.dup

    vlan_setting.native_vlan_id = 3
    assert_equal({ trunk: true, native_vlan_id: 3, allowed_vlan_id_list: '1-3' }, vlan_setting.send(:build_changelist))
    vlan_setting.instance_variable_set :@old, vlan_setting.dup

    vlan_setting.operation_mode = :Private
    assert_equal({ isolated: true, primary_vlan_id: 3, secondary_vlan_id: 4 }, vlan_setting.send(:build_changelist))
    vlan_setting.instance_variable_set :@old, vlan_setting.dup

    vlan_setting.private_vlan_mode = :Community
    assert_equal({ community: true, primary_vlan_id: 3, secondary_vlan_id: 4 }, vlan_setting.send(:build_changelist))
    vlan_setting.instance_variable_set :@old, vlan_setting.dup

    vlan_setting.private_vlan_mode = :Promiscuous
    assert_equal({ promiscuous: true, primary_vlan_id: 3, secondary_vlan_id_list: '1-3' }, vlan_setting.send(:build_changelist))
    vlan_setting.instance_variable_set :@old, vlan_setting.dup

    vlan_setting.primary_vlan_id = 4
    assert_equal({ promiscuous: true, primary_vlan_id: 4, secondary_vlan_id_list: '1-3' }, vlan_setting.send(:build_changelist))
    vlan_setting.instance_variable_set :@old, vlan_setting.dup
  end
end

