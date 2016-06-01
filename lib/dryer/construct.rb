# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby
module Dryer
  module Construct
    class << self
      def included(klass)
        define_construct(klass)
      end

      def define_construct(klass)
        local_klass = klass

        klass.define_singleton_method(:construct) do |*args, &block|
          required = args.dup
          optional = required[-1].class == Hash ? required.pop : {}
          perform_freeze = optional.delete(:freeze) == false ? false : true
          required = required.uniq

          keys = required + optional.keys
          local_klass.__send__(:attr_reader, *keys)
          local_klass.__send__(:private, *keys)

          define_method(:initialize) do |initialize_args = {}|
            missing = (required - initialize_args.keys)
            raise(ArgumentError, "missing keyword(s): #{missing.join(', ')}") if missing.any?
            combined = optional.merge(initialize_args)
            combined.each { |key, value| instance_variable_set("@#{key}", value) }
            instance_eval(&block) if block
            freeze if perform_freeze
          end
        end
      end
    end
  end
end
