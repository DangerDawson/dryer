module Dryer
  module Cast
    class CastGroup
      def initialize(caster, *defaults, &block)
        @caster = caster
        @block = block
        @defaults = defaults
      end

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
        namespace = args.delete(:namespace)
        if namespace.present?
          args[:to] = [namespace.to_s.classify, name.to_s.classify].join("::")
        end
        [name, args]
      end

      def wrap
        instance_eval(&@block)
      end
    end
  end
end
