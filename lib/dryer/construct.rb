module Dryer
  class Construct < Module
    def included(klass)
      @klass = klass
      define_construct(klass)
    end

    def initialize(freeze: true)
      @freeze = freeze
      @required = []
      @optional = {}
      @klass = nil
    end

    def public(*args)
      parse_args(args, :public)
    end

    def private(*args)
      parse_args(args, :private)
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

    def define_construct(klass)
      instance_self = self
      klass.define_singleton_method(:construct) do |*args, &block|
        instance_self.private(*args)
        define_method(:initialize) do |initialize_args = {}|
          instance_self.__send__(:define_initialize, self, initialize_args, &block)
        end
        instance_self
      end
    end
  end
end
