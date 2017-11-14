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
              if new_#{name}.is_a?(Fixnum)
                if _values.class.to_s == 'Array' # TODO: Better way to do class comparison in generated code
                  raise Fog::Hyperv::Errors::ServiceError, "\#{new_#{name}} is not in the range (0..\#{_values.length - 1})" unless new_#{name} >= 0 && new_#{name} < _values.length
                else
                  raise Fog::Hyperv::Errors::ServiceError, "\#{new_#{name}} is not one of \#{_values.is_a?(Hash) ? _values.keys : _values})" unless (_values.is_a?(Hash) ? _values.keys : _values).include? new_#{name}
                end

                attributes[:#{name}] = _values[new_#{name}]
              elsif new_#{name}.nil?
                attributes[:#{name}] = nil
              else
                new_#{name} = new_#{name}.to_s.to_sym unless new_#{name}.is_a? String
                raise Fog::Hyperv::Errors::ServiceError, "\#{new_#{name}} is not one of \#{_values.is_a?(Hash) ? _values.keys : _values})" unless (_values.is_a?(Hash) ? _values.keys : _values).include? new_#{name}
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
              return nil if self.#{name}.nil?
              if self.#{name}.is_a?(Fixnum)
                self.#{name}
              else
                if _values.is_a?(Hash)
                  _values.key(self.#{name})
                else
                  _values.index(self.#{name})
                end
              end
            end
        EOS
        super
      end
    end
  end
end
