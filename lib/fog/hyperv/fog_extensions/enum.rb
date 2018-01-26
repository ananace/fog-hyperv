module Fog
  module Attributes
    class Enum < Default
      attr_reader :values

      def initialize(model, name, options)
        @values = options.fetch(:values, [])
        super
      end

      def ensure_value_getter
        return if model.methods.include?("#{name}_values".to_sym)
        model.class_eval <<-EOS, __FILE__, __LINE__
            def #{name}_values
              #{values}.freeze
            end
        EOS
      end

      def create_setter
        ensure_value_getter
        model.class_eval <<-EOS, __FILE__, __LINE__
            def #{name}=(new_#{name})
              _values = #{name}_values
              # FIXME: Prepare a key comparison array in advance
              if new_#{name}.is_a?(Numeric)
                if _values.class.to_s == 'Array' # TODO: Better way to do class comparison in generated code
                  raise Fog::Hyperv::Errors::ServiceError, "\#{new_#{name}} is not in the range (0..\#{_values.length - 1})" unless new_#{name} >= 0 && new_#{name} < _values.length
                  attributes[:#{name}] = _values[new_#{name}]
                else
                  raise Fog::Hyperv::Errors::ServiceError, "\#{new_#{name}.inspect} is not one of \#{_values.is_a?(Hash) ? _values.values : _values})" unless (_values.is_a?(Hash) ? _values.values : _values).include? new_#{name}
                  attributes[:#{name}] = _values.key(new_#{name})
                end
              elsif new_#{name}.nil?
                attributes[:#{name}] = nil
              else
                new_#{name} = new_#{name}.to_s.to_sym unless new_#{name}.is_a? Symbol
                raise Fog::Hyperv::Errors::ServiceError, "\#{new_#{name}.inspect} is not one of \#{_values.is_a?(Hash) ? _values.keys : _values})" unless (_values.is_a?(Hash) ? _values.keys : _values).include? new_#{name}
                attributes[:#{name}] = new_#{name}
              end
            end
        EOS
      end

      def create_getter
        ensure_value_getter
        model.class_eval <<-EOS, __FILE__, __LINE__
            def #{name}_num
              _values = #{name}_values
              _attrib = attributes[:#{name}]

              return nil if _attrib.nil?
              if _attrib.is_a?(Numeric)
                _attrib
              else
                if _values.is_a?(Hash)
                  _values.send(:[],_attrib)
                else
                  _values.index(_attrib)
                end
              end
            end
        EOS
        super
      end
    end
  end
end
