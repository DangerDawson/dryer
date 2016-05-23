module Dryer
  module Cast
    class CastGroup
      def initialize(caster, *defaults, &block)
        @caster = caster
        @block = block
        @defaults = defaults
      end

      def wrap
        instance_eval(&block)
      end

      private
      attr_reader :caster, :block, :defaults

      def cast(*args)
        caster.cast(*merge_params(*args))
      end

      def cast_group(*args, &block)
        caster.cast_group(*merge_params(*args), &block)
      end

      def merge_params(*args)
        name = args.shift
        args = (defaults + args).reduce({}, :merge)
        [name, args]
      end
    end
  end
end
