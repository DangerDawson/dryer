module Dryer
  module Cast
    class CastGroup
      def initialize(caster, *defaults, &block)
        @caster = caster
        @block = block
        @defaults = defaults
      end

      def wrap
        instance_eval(&@block)
      end

      private

      def cast_wrapper(*args)
        @caster.cast(*merge_params(*args))
      end

      def cast(*args)
        cast_wrapper(*args)
      end

      def cast_private(*args)
        cast_wrapper(*args)
      end

      def cast_group(*args, &block)
        caster.cast_group(*args, &block)
      end

      def merge_params(*args)
        name = args.shift
        args = (@defaults + args).reduce({}, :merge)
        [name, args]
      end
    end
  end
end
