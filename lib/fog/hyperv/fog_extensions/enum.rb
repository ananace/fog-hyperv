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
                attributes[:#{name}] = #{values}[new_#{name}]
              elsif new_#{name}.is_a?(String)
                attributes[:#{name}] = new_#{name}.to_sym
              else
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
                #{values}.index(self.#{name})
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
