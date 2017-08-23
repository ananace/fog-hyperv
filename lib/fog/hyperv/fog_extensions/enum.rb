module Fog
  module Attributes
    class Enum < Default
      attr_reader :values

      def initialize(model, name, options)
        @values = options.fetch(:values, [])
        super
      end

      def create_setter
        model.class_eval <<-EOS, __FILE__, __LINE__
            def #{name}=(new_#{name})
              if new_#{name}.is_a?(Fixnum)
                raise Fog::Hyperv::Errors::ServiceError, "\#{new_#{name}} is not in the range (0..#{values.length - 1})" unless new_#{name} >= 0 && new_#{name} < #{values.length}
                attributes[:#{name}] = #{values}[new_#{name}]
              elsif new_#{name}.nil?
                attributes[:#{name}] = nil
              else
                new_#{name} = new_#{name}.to_s.to_sym unless new_#{name}.is_a? String
                raise Fog::Hyperv::Errors::ServiceError, "\#{new_#{name}} is not one of #{values.is_a?(Hash) ? values.values : values})" unless #{(values.is_a?(Hash) ? values.values : values)}.include? new_#{name}
                attributes[:#{name}] = new_#{name}
              end
            end
        EOS
      end

      def create_getter
        model.class_eval <<-EOS, __FILE__, __LINE__
            def #{name}_num
              return nil if self.#{name}.nil?
              if self.#{name}.is_a?(Fixnum)
                self.#{name}
              else
                if #{values}.is_a?(Hash)
                  #{values}.key(self.#{name})
                else
                  #{values}.index(self.#{name})
                end
              end
            end

            def #{name}_values
              #{values}.freeze
            end
        EOS
        super
      end
    end
  end
end
