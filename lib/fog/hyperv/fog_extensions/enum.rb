# frozen_string_literal: true

module Fog
  module Attributes
    class Enum < Default
      attr_reader :values

      def initialize(model, name, options)
        @values = options.fetch(:values, [])

        raise Fog::Hyperv::Errors::ServiceError, "#{values} is not a valid array or hash" \
          unless values.class.to_s == 'Array' || values.class.to_s == 'Hash'

        super
      end

      def ensure_value_getter
        return if model.private_methods.include?("#{name}_values".to_sym)

        model.class_eval <<-EOS, __FILE__, __LINE__
            private
            def #{name}_values
              #{values}.freeze
            end
        EOS
      end

      def create_setter
        ensure_value_getter

        # Add a setter that always stores a symbol value
        model.class_eval <<-EOS, __FILE__, __LINE__
            def #{name}=(new_value)
              _values = #{name}_values
              if new_value.is_a?(Numeric)
                # TODO: Better way to do class comparison in generated code
                if _values.class.to_s == 'Array'
                  raise Fog::Hyperv::Errors::ServiceError, "\#{new_value} is not in the range (0..\#{_values.length - 1})" \
                    unless new_value >= 0 && new_value < _values.length
                  attributes[:#{name}] = _values[new_value]
                elsif _values.class.to_s == 'Hash'
                  raise Fog::Hyperv::Errors::ServiceError, "\#{new_value} is not one of \#{_values.values})" \
                    unless _values.values.include? new_value
                  attributes[:#{name}] = _values.key(new_value)
                end
              elsif new_value.nil?
                attributes[:#{name}] = nil
              else
                new_value = new_value.to_s.to_sym unless new_value.is_a? Symbol
                # Ensure values is the array of enum symbols
                _values = (_values.is_a?(Hash) ? _values.keys : _values)
                raise Fog::Hyperv::Errors::ServiceError, "\#{new_value.inspect} is not one of \#{_values})" \
                  unless _values.include? new_value
                attributes[:#{name}] = new_value
              end
            end
        EOS
      end

      def create_getter
        ensure_value_getter

        # Add a getter for <enum>_num to get the numeric value
        model.class_eval <<-EOS, __FILE__, __LINE__
            def #{name}_num
              _values = #{name}_values
              _value = attributes[:#{name}]

              return nil if _value.nil?
              if _value.is_a?(Numeric)
                _value
              else
                if _values.is_a?(Hash)
                  _values.send(:[], _value)
                else
                  _values.index(_value)
                end
              end
            end
        EOS
        
        # Add the default getter for the symbol value
        super
      end
    end
  end
end
