require 'dryer/construct/unfreeze'
require 'dryer/construct/base_initialize'
module Dryer
  module Construct
    class << self
      def config(args = {})
        freeze = args.fetch(:freeze, true)
        Dryer::Construct::Base.new(freeze: freeze)
      end

      def included(klass)
        construct = Dryer::Construct::Base.new(freeze: freeze)
        construct.define_construct(klass)
      end
    end

    class Base < Module
      using Unfreeze
      def initialize(freeze: true, access: :private)
        @freeze = freeze
        @access = access
        @local_dave =  nil
        freeze
      end

      def included(model)
        super(model)
        define_construct(model)
      end

      def define_construct(model)
        local_freeze = @freeze
        local_access = @access

        model.define_singleton_method(:construct) do |*args, &block|
          self.include(BaseInitialize)

          before_freeze = nil
          required = args.dup
          optional = required[-1].class == Hash ? required.pop : {}

          if self.respond_to?(:optional) || self.respond_to?(:required)
            optional.merge!(self.optional)
            required += self.required
          end
          required = required.uniq

          self.define_singleton_method(:optional) { optional }
          self.define_singleton_method(:required) { required }

          define_singleton_method(:before_freeze) { |&freeze_block| before_freeze = freeze_block }

          define_method(:initialize) do |**initialize_args|
            super(**initialize_args)
            self.unfreeze

            missing = (required - initialize_args.keys).uniq
            raise(ArgumentError, "missing keyword(s): #{missing.join(', ')}") if missing.any?

            combined = optional.merge(initialize_args)
            combined.each { |key, value| instance_variable_set("@#{key}", value) }

            self.class.__send__(:attr_reader, *combined.keys)
            self.class.__send__(local_access, *combined.keys)

            instance_eval(&block) if block
            instance_eval(&before_freeze) if before_freeze
            self.freeze if local_freeze
          end
        end
      end
    end
  end
end
