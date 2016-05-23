require "active_support/core_ext/string"
module Dryer
  module Cast
    def self.base(namespace: nil)
      ::Dryer::Cast::Base.new(namespace)
    end

    class Base < Module
      attr_reader :namespace
      attr_accessor :cast_methods
      def initialize(namespace)
        @namespace = namespace
        @cast_methods = Set.new
      end

      private

      def included(klass)
        define_macro(klass)
        local_cast_methods = cast_methods
        define_method(:cast_methods) { local_cast_methods.to_a }
        klass.define_singleton_method(:cast_methods) { local_cast_methods.to_a }
      end

      def define_macro(klass)
        define_cast_singleton(klass, :cast, :public)
        define_cast_singleton(klass, :cast_private, :private)
      end

      def define_cast_singleton(klass, mode, visibility, &block)
        local_namespace = namespace
        local_cast_methods = cast_methods
        klass.define_singleton_method mode do |*macro_args, &_macro_block|
          name = macro_args.shift
          options = macro_args.shift || {}
          explicit_klass = options[:to]

          define_method(name) do |*args, &method_block|
            implicit_klass = [local_namespace, name.to_s.classify].join("::")
            delegate_klass = explicit_klass ? explicit_klass : implicit_klass
            delegate_instance = delegate_klass.constantize.new(caster: self)

            if delegate_instance.method(:call).arity.zero?
              delegate_instance.call(&method_block)
            else
              delegate_instance.call(*args, &method_block)
            end
          end
          local_cast_methods << name
          __send__(visibility, name)
        end
      end
    end
  end
end
