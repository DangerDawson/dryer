module Dryer
  module Cast
    class CastGroup
      def initialize(caster, defaults, &block)
        @caster = caster
        @block = block
        @defaults = defaults
      end

      def wrap
        instance_eval(&block)
      end

      private

      attr_reader :caster, :block, :defaults

      def cast(name, args = {})
        merged_args = merge_args(args)
        caster.cast(name, merged_args)
      end

      def cast2(name, args = {})
        merged_args = merge_args(args)
        caster.cast2(name, merged_args)
      end

      def cast_group(args, &block)
        merged_args = merge_args(args)
        caster.cast_group(merged_args, &block)
      end

      def merge_args(args)
        args.each_with_object(defaults.dup) do |(key, value), object|
          object[key] = if object.key?(key)
                          [*object[key]] + [*value]
                        else
                          value
                        end
        end
      end
    end
  end
end
