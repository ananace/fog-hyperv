module Fog
  module Compute
    class Hyperv
      class ComPort < Fog::Hyperv::Model
        identity :id

        attribute :computer_name
        attribute :debugger_mode, type: :enum, values: [ :On, :Off ]
        attribute :name
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
