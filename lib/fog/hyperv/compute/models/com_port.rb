# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class ComPort < Fog::Hyperv::Model
        # @!attribute [r] id
        #   @return [String] The GUID of the COM port
        identity :id

        # @!attribute [r] computer_name
        #   @return [String] The name of the computer running the VM this COM port is attached to
        attribute :computer_name

        # @!attribute [r] debugger_mode
        #   @return [:On, :Off] If a debugger is enabled on this COM port
        attribute :debugger_mode, type: :enum, values: %i[On Off]
        # @!attribute [r] name
        #   @return [String] The name of this COM port
        attribute :name
        # @!attribute [r] path
        #   @return [String] The path of this COM port
        attribute :path

        def save
          raise Fog::Errors::NotImplemented
        end

        def reload
          raise Fog::Errors::NotImplemented
        end
      end
    end
  end
end
