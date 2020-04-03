# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_switch(options = {})
          if options[:_quick_query]
            search = {}
            search[:element_name] = options[:name] if options[:name]
            search[:name] = options[:id].upcase if options[:id]
            data = run_wql('SELECT ElementName,Name FROM Msvm_VirtualEthernetSwitch', search)
            nil if data.empty?
            data[:xml_fragment].map do |sw|
              {
                id: sw[:name].downcase,
                computer_name: options[:computer_name],
                name: sw[:element_name],
              }
            end
          else
            run_shell('Get-VMSwitch', options)
          end
        end
      end
    end
  end
end

