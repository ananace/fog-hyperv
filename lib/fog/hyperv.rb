require 'fog/core'

module Fog
  module Compute
    autoload :Hyperv, File.expand_path('../hyperv/compute', __FILE__)
  end

  module Hyperv
    extend Fog::Provider

    module Errors
      class ServiceError < Fog::Errors::Error; end
      class PSError < ServiceError
        attr_reader :stdout, :stderr, :exitcode, :info

        def initialize(output, info)
          @stdout = output.stdout
          @stderr = output.stderr
          @exitcode = output.exitcode
          @info = info

          super @stderr.split("\n").first
        end

        def to_s
          ret = [super]
          ret << info unless info.nil? || info.empty?
          ret.join "\n"
        end
      end
    end

    autoload :Collection, File.expand_path('../collection', __FILE__)
    autoload :Model, File.expand_path('../model', __FILE__)
    autoload :ModelExtends, File.expand_path('../model', __FILE__)
    autoload :ModelIncludes, File.expand_path('../model', __FILE__)
    autoload :VMCollection, File.expand_path('../collection', __FILE__)

    service(:compute, 'Compute')

    def self.shell_quoted(data, always = false)
      case data
      when String
        if data =~ /(^$)|\s/ || always
          data.gsub(/`/, '``')
              .gsub(/\0/, '`0')
              .gsub(/\n/, '`n') 
              .gsub(/\r/, '`r') 
              .inspect
        else
          data
        end
      when Array
        '@(' + data.map { |e| shell_quoted(e, true) }.join(', ') + ')'
      when FalseClass
        '$false'
      when TrueClass
        '$true'
      else
        shell_quoted data.to_s
      end
    end

    def self.camelize(data)
      case data
      when Array
        data.collect { |d| camelize(d) }
      when Hash
        data.each_with_object({}) do |(k, v), hash|
          value = v
          value = camelize(v) if v.is_a?(Hash) || (v.is_a?(Array) && v.all? { |h| h.is_a?(Hash) })
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

    def self.uncamelize(data)
      case data
      when Array
        data.collect { |d| uncamelize(d) }
      when Hash
        data.each_with_object({}) do |(k, v), hash|
          value = v
          value = uncamelize(v) if v.is_a?(Hash) || (v.is_a?(Array) && v.all? { |h| h.is_a?(Hash) })
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
