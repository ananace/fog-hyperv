module Fog
  module Hyperv
    class ModelExtensions
      private

      def changed? attr
        attributes.select { |k,v| old.attributes[k] != v }.key?(attr)
      end

      def old
        @old ||= self.dup.reload
      end
    end
  end
end
