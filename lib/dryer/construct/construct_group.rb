module Dryer
  module Construct
    class ConstructGroup
      def initialize(constructer, defaults, &block)
        @constructer = constructer
        @block = block
        @defaults = defaults
      end

      def wrap
        instance_eval(&block)
      end

      private

      attr_reader :constructer, :block, :defaults

      def construct(name, args = {})
        merged_args = merge_args(args)
        constructer.construct(name, merged_args)
      end

      def construct_group(args, &block)
        merged_args = merge_args(args)
        constructer.construct_group(merged_args, &block)
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
