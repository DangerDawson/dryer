module Dryer
  module Construct
    def self.included(klass)
      base = Dryer::Construct::Base.new(klass: klass)
      base.define_construct
    end

    def self.config(args = {})
      Module.new do
        @config = args
        def self.included(klass)
          freeze = @config.fetch(:freeze, true)
          base = Dryer::Construct::Base.new(klass: klass, freeze: freeze)
          base.define_construct
        end
      end
    end

    class Base
      def initialize(klass:, freeze: true)
        @freeze = freeze
        @required = []
        @optional = {}
        @klass = klass
      end

      def public(*args)
        parse_args(args, :public)
      end

      def private(*args)
        parse_args(args, :private)
      end

      def define_construct
        instance_self = self
        @klass.define_singleton_method(:construct) do |*args, &block|
          instance_self.private(*args)
          define_method(:initialize) do |initialize_args = {}|
            instance_self.__send__(:define_initialize, self, initialize_args, &block)
          end
          instance_self
        end
      end

      private

      def parse_args(args, access)
        required = args.dup
        optional = required[-1].class == Hash ? required.pop : {}
        required = required.uniq

        set_attr_readers(required, optional, access)
        merge_args(required, optional)
      end

      def set_attr_readers(required, optional, access)
        keys = required + optional.keys
        @klass.__send__(:attr_reader, *keys)
        @klass.__send__(access, *keys)
      end

      def merge_args(required, optional)
        @optional.merge!(optional)
        @required.concat(required).uniq
      end

      def define_initialize(local_self, initialize_args, &block)
        missing = (@required - initialize_args.keys).uniq
        raise(ArgumentError, "missing keyword(s): #{missing.join(', ')}") if missing.any?
        combined = @optional.merge(initialize_args)
        combined.each { |key, value| local_self.instance_variable_set("@#{key}", value) }
        local_self.instance_eval(&block) if block
        local_self.freeze if @freeze
      end
    end
  end
end
