# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def new_vm(options = {})
          options[:memory_startup_bytes] = options.delete :memory_startup if options.key? :memory_startup

          requires options, :new_vhd_path, :new_vhd_size_bytes \
            if options[:new_whd_path] || options[:new_vhd_size_bytes]
          run_shell('New-VM', options)
        end
      end
    end
  end
end
