# frozen_string_literal: true

module Fog
  module Attributes
    class Hypervenum < Default
      attr_reader :values

      def initialize(model, name, options)
        @values = options.fetch(:values)

        raise Fog::Hyperv::Errors::ServiceError, "#{values} is not a valid array or hash" \
          unless %w[Array Hash].include?(values.class.to_s)

        super
      end

      # rubocop:disable Style/DocumentDynamicEvalDefinition -- Reporting false positive
      def ensure_value_getter
        return if model.private_method_defined?(:"#{name}_values")

        model.class_eval <<-VALUE_GETTER, __FILE__, __LINE__ + 1
          # private
          # def state_values
          #   { Unknown: 1, Running: 2 }.freeze
          # end

          private
          def #{name}_values
            #{values}.freeze
          end
        VALUE_GETTER
      end

      def create_setter
        ensure_value_getter

        # Add a setter that always stores a symbol value
        model.class_eval <<-SETTER, __FILE__, __LINE__ + 1
          # def state=(new_value)
          #   _values = state_values
          #   if new_value.is_a?(Numeric)
          #     # TODO: Better way to do class comparison in generated code
          #     if _values.class.to_s == 'Array'
          #       raise Fog::Hyperv::Errors::ServiceError, "\#{new_value} is not in the range (0..\#{_values.length - 1})" \
          #         unless new_value >= 0 && new_value < _values.length
          #       attributes[:state] = _values[new_value]
          #     elsif _values.class.to_s == 'Hash'
          #       raise Fog::Hyperv::Errors::ServiceError, "\#{new_value} is not one of \#{_values.values})" \
          #         unless _values.values.include? new_value
          #       attributes[:state] = _values.key(new_value)
          #     end
          #   elsif new_value.nil?
          #     attributes[:state] = nil
          #   else
          #     new_value = new_value.to_s.to_sym unless new_value.is_a? Symbol
          #     # Ensure values is the array of enum symbols
          #     _values = (_values.is_a?(Hash) ? _values.keys : _values)
          #     raise Fog::Hyperv::Errors::ServiceError, "\#{new_value.inspect} is not one of \#{_values})" \
          #       unless _values.include? new_value
          #     attributes[:state] = new_value
          #   end
          # end

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
        SETTER
      end

      def create_getter
        ensure_value_getter

        # Add a getter for <enum>_num to get the numeric value
        model.class_eval <<-GETTER_NUM, __FILE__, __LINE__ + 1
          # def state_num
          #   _values = state_values
          #   _value = attributes[:state]
          #
          #   return nil if _value.nil?
          #   if _value.is_a?(Numeric)
          #     _value
          #   else
          #     if _values.is_a?(Hash)
          #       _values.send(:[], _value)
          #     else
          #       _values.index(_value)
          #     end
          #   end
          # end


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
        GETTER_NUM

        # Add the default getter for the symbol value
        super
      end
      # rubocop:enable Style/DocumentDynamicEvalDefinition
    end
  end
end
