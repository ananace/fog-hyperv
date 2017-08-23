module Fog
  module Compute
    class Hyperv
      class Real
        def get_vhd(options = {})
          requires_one options, :vm_id, :path, :disk_number
          run_shell('Get-VHD', options)
        end
      end

      class Mock
        def get_vhd(args = {})
          requires_one args, :vm_id, :path, :disk_number
          data = handle_mock_response args

          if args[:vm_id]
            data = case args[:vm_id].downcase
                   when '20ff7fe3-fd54-425c-aa97-fbf3c2e7a868'
                     data[1..-1]
                   when '416e49fd-28dd-413c-9743-aa3e69e4807d'
                     data[0]
                   end
          elsif args[:path]
            data = data.find { |d| d[:path].casecmp(args[:path]).zero? }
          elsif args[:disk_number]
            Fog::Mock.not_implemented
          end

          data
        end
      end
    end
  end
end
