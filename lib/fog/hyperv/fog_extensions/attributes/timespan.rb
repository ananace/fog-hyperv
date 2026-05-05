# frozen_string_literal: true

module Fog::Attributes
  class Hypervtimespan < Fog::Attributes::Default
    # rubocop:disable Style/DocumentDynamicEvalDefinition
    def create_setter
      model.class_eval <<-SETTER, __FILE__, __LINE__ + 1
        def #{name}=(new_#{name})
          if new_#{name}.is_a?(Hash)
            attributes[:#{name}] = new_#{name}[:total_seconds]
          else
            h, m, s = new_#{name}.split(':').map(&:to_f)
            attributes[:#{name}] = h * 3600 + m * 60 + s
          end
        end
      SETTER
    end
    # rubocop:enable Style/DocumentDynamicEvalDefinition
  end
end
