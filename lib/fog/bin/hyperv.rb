class Hyperv < Fog::Bin
  class << self
    def class_for(key)
      case key
      when :compute
        Fog::Compute::Hyperv
      else
        raise ArgumentError, "Unsupported #{self} service: #{key}"
      end
    end

    def [](service)
      @@connections ||= Hash.new do |h, k|
        h[k] = case key
               when :compute
                 Fog::Compute.new(provider: 'Hyperv')
               else
                 raise ArgumentError, "Unrecognized service: #{key.inspect}"
               end
      end
      @@connections[service]
    end

    def services
      Fog::Hyperv.services
    end
  end
end
