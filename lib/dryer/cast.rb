require "dryer/cast/cast_group"
require "active_support/core_ext/string"
module Dryer
  module Cast
    module Memoize
      def initialize(*args)
        @_memoize_storage = {}
        super(*args)
      end
    end

    class << self
      attr_accessor :cast_methods

      def included(klass)
        @cast_methods = {}
        klass.prepend Dryer::Cast::Memoize
        define_macro(klass)
        local_cast_methods = cast_methods
        klass.define_singleton_method(:cast_methods) { local_cast_methods }
      end

      private

      def define_macro(klass)
        define_cast_group_singleton(klass)
        define_cast_singleton(klass)
      end

      def define_cast_group_singleton(klass)
        klass.define_singleton_method :cast_group do |args = {}, &block|
          CastGroup.new(klass, args, &block).wrap
        end
      end

      def eval_target
        proc do |constructor_args, target_klass, *args|
          constructor_params = constructor_args.each_with_object({}) do |method, object|
            if method.class == Hash
              method.each_with_object(object) do |(method2, local_method), object2|
                object2[method2] = local_method == :self ? self : send(local_method)
              end
            else
              object[method] = send(method)
            end
          end
          target_instance = Kernel.const_get(target_klass).new(constructor_params)

          if target_instance.method(:call).arity.zero?
            target_instance.call
          else
            target_instance.call(*args)
          end
        end
      end

      def define_cast_singleton(klass)
        local_cast_methods = @cast_methods
        local_eval_target = eval_target

        klass.define_singleton_method(:cast) do |*macro_args|
          name = macro_args.shift
          options = macro_args.shift || {}
          constructor_args = [*options[:with]]
          access = options[:access] ? [*options[:access]].last : :public
          namespace = options[:namespace]
          memoize = options[:memoize] ? true : false
          target_klass = [namespace, options.fetch(:to, name.to_s.classify)].compact.join("::")

          define_method(name) do |*args|
            if memoize
              @_memoize_storage ||= {}
              @_memoize_storage[name] ||= {}
              constructor_key = frozen? ? object_id : constructor_args
              @_memoize_storage[name][constructor_key] ||= {}
              if @_memoize_storage[name][constructor_key].key?(args)
                @_memoize_storage[name][constructor_key][args]
              else
                @_memoize_storage[name][constructor_key][args] =
                  instance_exec(constructor_args, target_klass, *args, &local_eval_target)
              end
            else
              instance_exec(constructor_args, target_klass, *args, &local_eval_target)
            end
          end
          local_cast_methods[name] = { to: target_klass, with: constructor_args, memoize: memoize }
          __send__(access, name)
        end
      end
    end
  end
end
