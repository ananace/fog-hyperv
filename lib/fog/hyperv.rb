# frozen_string_literal: true

require 'fog/core'

module Fog
  module Attributes
    autoload :Hypervdatetime, File.expand_path('hyperv/fog_extensions/attributes/datetime.rb', __dir__)
    autoload :Hypervenum, File.expand_path('hyperv/fog_extensions/attributes/enum.rb', __dir__)
    autoload :Hypervenumarray, File.expand_path('hyperv/fog_extensions/attributes/enumarray.rb', __dir__)
    autoload :Hypervtimespan, File.expand_path('hyperv/fog_extensions/attributes/timespan.rb', __dir__)
  end

  module Hyperv
    extend Fog::Provider

    autoload :Compute, File.expand_path('hyperv/compute', __dir__)

    # General GUID format matching the UUIDv4 specification
    GUID = /[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}/i

    module Errors
      # A general service error occurred
      class ServiceError < Fog::Errors::Error; end

      # A version constrain was not matched
      class VersionError < ServiceError
        attr_reader :version, :required_version, :function

        def initialize(required_version, version, function)
          @function = function
          @required_version = required_version
          @version = version

          super("#{function} requires at least Hyper-V v#{required_version}, you have v#{version}")
        end
      end

      # A powershell call failed
      class PSError < ServiceError
        attr_reader :stdout, :stderr, :exitcode, :info, :message

        def initialize(output, info)
          @stdout = output.stdout
          @stderr = output.stderr
          @exitcode = output.exitcode
          @info = info
          @message = @stderr.split("\n").first
          super(@message)
        end

        def to_s
          ret = [super]
          ret << info unless info.nil? || info.empty?
          ret.join "\n"
        end
      end
    end

    module Associations
      autoload :Collection, File.expand_path('hyperv/fog_extensions/associations/collection', __dir__)
    end

    module Utils
      autoload :Powershell, File.expand_path('hyperv/utils/powershell', __dir__)
      autoload :Winrm, File.expand_path('hyperv/utils/winrm', __dir__)
    end

    autoload :Collection, File.expand_path('hyperv/collection', __dir__)
    autoload :Model, File.expand_path('hyperv/model', __dir__)
    autoload :ModelExtends, File.expand_path('hyperv/model', __dir__)
    autoload :ModelIncludes, File.expand_path('hyperv/model', __dir__)
    autoload :VMCollection, File.expand_path('hyperv/collection', __dir__)

    service(:compute, 'Compute')

    # Convert a piece of data from being snake_case to being CamelCase
    def self.camelize(data)
      case data
      when Array
        data.collect { |d| camelize(d) }
      when Hash
        data.each_with_object({}) do |(k, v), hash|
          value = v
          value = camelize(v) if v.is_a?(Hash) || (v.is_a?(Array) && v.all?(Hash))
          hash[camelize(k)] = value
        end
      when Symbol
        camelize(data.to_s).to_sym
      when String
        data.split('_').collect(&:capitalize).join
      else
        data
      end
    end

    # Convert a piece of data from being CamelCase to being snake_case
    def self.uncamelize(data)
      case data
      when Array
        data.collect { |d| uncamelize(d) }
      when Hash
        data.each_with_object({}) do |(k, v), hash|
          value = v
          value = uncamelize(v) if v.is_a?(Hash) || (v.is_a?(Array) && v.all?(Hash))
          hash[uncamelize(k)] = value
        end
      when Symbol
        uncamelize(data.to_s).to_sym
      when String
        data.to_s
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr('-', '_')
            .downcase.to_sym
      else
        data
      end
    end
  end
end
