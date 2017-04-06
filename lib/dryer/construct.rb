require "dryer/construct/base_initialize"
module Dryer
  module Construct
    class << self
      def config(args = {})
        freeze = args.fetch(:freeze, true)
        access = args.fetch(:access, :private)
        Dryer::Construct::Base.new(freeze: freeze, access: access)
      end

      def included(klass)
        construct = Dryer::Construct::Base.new
        construct.define_construct(klass)
        klass.construct
      end
    end

    class Base < Module
      def initialize(freeze: true, access: :private)
        @freeze = freeze
        @access = access
        self.freeze
      end

      def included(model)
        super(model)
        define_construct(model)
      end

      def define_construct(model)
        local_freeze = @freeze
        local_access = @access

        model.define_singleton_method(:construct) do |*args, &block|
          include(BaseInitialize)

          required = args.dup
          optional = required[-1].class == Hash ? required.pop : {}

          define_method(:param) do |*param_args|
            key, value = param_args
            if param_args.size > 1
              instance_variable_set("@#{key}", value)
            else
              required << key
            end
            self.class.__send__(:attr_reader, key)
            self.class.__send__(local_access, key)
          end

          define_method(:initialize) do |**initialize_args|
            _initialize_without_freeze(initialize_args)
            freeze if local_freeze
          end

          define_method(:_initialize_without_freeze) do |**initialize_args|
            super(**initialize_args)

            combined = optional.merge(initialize_args)
            combined.each { |key, value| param(key, value) }

            instance_eval(&block) if block

            missing = (required - initialize_args.keys).uniq
            if missing.any?
              message = "class: #{self.class}, missing keyword(s): #{missing.join(', ')}"
              raise(ArgumentError, message)
            end
          end
        end
      end
    end
  end
end
