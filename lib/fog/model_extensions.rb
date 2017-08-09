module Fog
  module Hyperv
    module ModelExtensions
      private

      def changed?(attr)
        attributes.reject { |k, v| old.attributes[k] == v }.key?(attr)
      end

      def old
        @old ||= dup.reload
      end
    end
  end
end
