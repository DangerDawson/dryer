require 'active_support/core_ext/string'
module Dryer
  module Cast
    def self.base(namespace: nil)
      ::Dryer::Cast::Base.new(namespace)
    end

    class Base < Module
      attr_reader :namespace
      def initialize(namespace)
        @namespace = namespace
      end

      def included(klass)
        define_macro(klass)
      end

      def define_macro(klass)
        local_namespace = namespace
        klass.define_singleton_method :cast do |*macro_args, &_macro_block|
          name = macro_args.shift
          options = macro_args.shift || {}
          explicit_klass = options[:class_name]

          define_method(name) do |*args, &block|
            implicit_klass = [local_namespace, name.to_s.classify].join("::")
            delegate_klass = explicit_klass ? explicit_klass : implicit_klass
            delegate_instance = delegate_klass.constantize.new(sender: self)

            if delegate_instance.method(:call).arity.zero?
              delegate_instance.call(&block)
            else
              delegate_instance.call(*args, &block)
            end
          end
        end

        klass.define_singleton_method :cast_private do |*macro_args, &_macro_block|
          name = macro_args.shift
          options = macro_args.shift || {}
          explicit_klass = options[:class_name]

          define_method(name) do |*args, &block|
            implicit_klass = [local_namespace, name.to_s.classify].join("::")
            delegate_klass = explicit_klass ? explicit_klass : implicit_klass
            delegate_instance = delegate_klass.constantize.new(sender: self)
            if delegate_instance.method(:call).arity.zero?
              delegate_instance.call(&block)
            else
              delegate_instance.call(*args, &block)
            end
          end
          __send__(:private, name)
        end


      end

    end
  end
end
