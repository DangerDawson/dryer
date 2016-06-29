module Dryer
  module Cast
    class CastRefine
      def initialize(default_namespace, refine_klass, &block)
        @default_namespace = default_namespace
        @refine_klass = refine_klass
        @block = block
      end

      def refine
        target_name = refine_klass.to_s.split("::")
        target_name.delete("Spree")
        namespace = (default_namespace + target_name).join("::")

        camelized_name = camelize(target_name.last)
        with = [camelized_name.to_sym => :self]

        local_refine_klass = refine_klass
        local_block = block
        Module.new do
          refine local_refine_klass do
            include ::Dryer::Cast.config(prepend: false, namespace: namespace, with: with)
            module_eval(&local_block)
          end
        end
      end

      private

      attr_reader :default_namespace, :refine_klass, :block

      # TODO Dry up
      def camelize(str)
        str.split("_").map(&:capitalize).join
      end

    end
  end
end
