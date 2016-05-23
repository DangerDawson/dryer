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
        define_cast_singleton(klass, :cast, :public)
        define_cast_singleton(klass, :cast_private, :private)
      end

      def define_cast_group_singleton(klass)
        klass.define_singleton_method :cast_group do |*args, &block|
          CastGroup.new(klass, *args, &block).wrap
        end
      end

      def define_cast_singleton(klass, mode, _visibility, &block)
        local_cast_methods = cast_methods
        klass.define_singleton_method mode do |*macro_args, &_macro_block|
          name = macro_args.shift
          options = macro_args.shift || {}
          explicit_klass = options[:to]
          constructor_args = [*options[:with]]
          access = options[:access] || :public

          define_method(name) do |*args, &method_block|
            #implicit_klass = [name_space, name.to_s.classify].join("::")
            implicit_klass = [name.to_s.classify].join("::")
            delegate_klass = explicit_klass ? explicit_klass : implicit_klass

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
            delegate_instance = delegate_klass.constantize.new(constructor_params)

            if delegate_instance.method(:call).arity.zero?
              delegate_instance.call(&method_block)
            else
              delegate_instance.call(*args, &method_block)
            end
          end
          local_cast_methods << name
          __send__(access, name)
        end
      end
    end
  end
end
