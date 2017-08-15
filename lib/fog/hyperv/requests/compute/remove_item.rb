module Fog
  module Compute
    class Hyperv
      class Real
        def remove_item(options = {})
          run_shell('Remove-Item', options.merge(force: true, _skip_json: true)).exitcode.zero?
        end
      end
    end
  end
end
