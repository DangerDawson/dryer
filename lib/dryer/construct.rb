# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby
require 'pry'
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

      keys = required + optional.keys
      @klass.__send__(:attr_reader, *keys)
      @klass.__send__(access, *keys)

      @optional.merge!(optional)
      @required.concat(required).uniq
    end

    def define_construct(klass)
      perform_freeze = @freeze
      local_self = self
      local_optional = @optional
      local_required = @required

      klass.define_singleton_method(:construct) do |*args, &block|
        local_self.private(*args)

        define_method(:initialize) do |initialize_args = {}|
          missing = (local_required - initialize_args.keys).uniq
          raise(ArgumentError, "missing keyword(s): #{missing.join(', ')}") if missing.any?
          combined = local_optional.merge(initialize_args)
          combined.each { |key, value| instance_variable_set("@#{key}", value) }
          instance_eval(&block) if block
          freeze if perform_freeze
        end
        local_self
      end
    end
  end
end
