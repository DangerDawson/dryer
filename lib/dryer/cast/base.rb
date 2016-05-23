require "active_support/core_ext/string"
require "dryer/cast/cast_group"
module Dryer
  module Cast
    def self.base
      ::Dryer::Cast::Base.new
    end

    class Base < Module
      attr_accessor :cast_methods
      def initialize
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
        define_cast_group_singleton(klass)
        define_cast_singleton(klass)
      end

      def define_cast_group_singleton(klass)
        klass.define_singleton_method :cast_group do |*args, &block|
          CastGroup.new(klass, *args, &block).wrap
        end
      end

      def define_cast_singleton(klass, &block)
        local_cast_methods = cast_methods
        klass.define_singleton_method(:cast) do |*macro_args, &_macro_block|
          name = macro_args.shift
          options = macro_args.shift || {}
          constructor_args = [*options[:with]]
          access = options[:access] || :public
          namespace = options[:namespace]
          target_klass = [namespace, options.fetch(:to, name.to_s.classify)].compact.join("::")

          define_method(name) do |*args, &method_block|
            constructor_params = constructor_args.each_with_object({}) do |method, object|
              if method.class == Hash
                method.each_with_object(object) do |(method2, local_method), object2|
                  object2[method2] = send(local_method)
                end
              else
                object[method] = send(method)
              end
            end

            constructor_params[:caster] = self
            target_instance = target_klass.constantize.new(constructor_params)

            if target_instance.method(:call).arity.zero?
              target_instance.call(&method_block)
            else
              target_instance.call(*args, &method_block)
            end
          end
          local_cast_methods << name
          __send__(access, name)
        end
      end
    end
  end
end
