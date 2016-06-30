module Dryer
  module Construct
    class << self
      def config(args = {})
        Dryer::Construct::Base.new(freeze: freeze)
      end
    end

    class Base < Module
      def initialize(freeze: true)
        @freeze = freeze
      end

      def included(model)
        super(model)
        model.define_singleton_method(:construct) do |*args, &block|
          before_freeze = nil
          required = args.dup
          optional = required[-1].class == Hash ? required.pop : {}
          required = required.uniq

          define_method(:initialize) do |initialize_args = {}|
            #super(*initialize_args)

            missing = (required - initialize_args.keys).uniq
            raise(ArgumentError, "missing keyword(s): #{missing.join(', ')}") if missing.any?

            combined = optional.merge(initialize_args)
            combined.each { |key, value| instance_variable_set("@#{key}", value) }
            instance_eval(&block) if block

            access = :private
            keys = combined.keys
            self.class.__send__(:attr_reader, *keys)
            self.class.__send__(access, *keys)

            instance_eval(&before_freeze) if before_freeze

            freeze if @freeze
          end

          define_singleton_method(:before_freeze) do |&freeze_block|
            before_freeze = freeze_block
          end
        end
      end
    end
  end
end
