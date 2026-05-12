# frozen_string_literal: true

module Fog::Attributes
  # Fog attribute type for handling DateTime values from PowerShell
  class Hypervdatetime < Fog::Attributes::Default
    private

    # rubocop:disable Style/DocumentDynamicEvalDefinition

    def create_setter
      # Possible input values are;
      # /Date(123456789)/ - time since unix epoch in milliseconds
      # "2026-01-02T10:11:12Z" - DateTime in long-form parsable format
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
