# frozen_string_literal: true

module Fog::Attributes
  # Fog attribute type for handling TimeSpan values from PowerShell
  class Hypervtimespan < Fog::Attributes::Default
    private

    # rubocop:disable Style/DocumentDynamicEvalDefinition

    def create_setter
      # Possible input values are;
      # 00:00:00 - string-converted TimeSpan
      # {hours: 0, minutes: 0... total_seconds: 0} - hash containing the TimeSpan data
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
