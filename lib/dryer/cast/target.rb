module Dryer
  module Cast
    class Target < Module
      def initialize(accessors, visibility: :private)
        optional = accessors[-1].class == Hash ? accessors.pop : {}
        define_included(accessors, optional, visibility)
        define_initializer(accessors, optional)
        freeze
      end

      private

      # @api private
      def define_included(required, optional, visibility)
        define_singleton_method(:included) do |descendant|
          keys = required + optional.keys
          descendant.__send__(:attr_reader, *keys)
          descendant.__send__(visibility, *keys)
        end
      end

      # @api private
      def define_initializer(required, optional)
        define_method(:initialize) do |args = {}, &_block|
          missing = (required - args.keys)
          raise(ArgumentError, "missing keyword(s): #{missing.join(', ')}") if missing.any?
          combined = optional.merge(args)
          combined.each do |key, value|
            instance_variable_set("@#{key}", value)
          end
        end
      end
    end
  end
end
