# frozen_string_literal: true

module Fog::Attributes
  class Hypervdatetime < Fog::Attributes::Default
    # rubocop:disable Style/DocumentDynamicEvalDefinition
    def create_setter
      model.class_eval <<-SETTER, __FILE__, __LINE__ + 1
        def #{name}=(new_#{name})
          new_#{name} = new_#{name}.scan(/Date\\((\\d+)\\)/).flatten.first&.to_i if new_#{name}.include?('Date(')

          if new_#{name}.respond_to?(:to_i)
            attributes[:#{name}] = Fog::Time.at(new_#{name}.to_i / 1000.0)
          else
            attributes[:#{name}] = Fog::Time.parse(new_#{name}.to_s)
          end
        end
      SETTER
    end
    # rubocop:enable Style/DocumentDynamicEvalDefinition
  end
end
