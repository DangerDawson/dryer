require "dryer/cast/cast_group"
require "dryer/cast/memoize"
module Dryer
  module Cast
    class << self
      def included(klass)
        base = Dryer::Cast::Base.new(klass: klass)
        base.define_cast
      end

      def config(args = {})
        Module.new do
          @config = args
          class << self
            def included(klass)
              prepend = @config.fetch(:prepend, true)
              base = Dryer::Cast::Base.new(klass: klass, prepend: prepend)
              base.define_cast
            end
          end
        end
      end
    end

    class Base
      def initialize(klass:, prepend: true)
        @prepend = prepend
        @klass = klass
        @cast_methods = {}
        @_memoize_storage = {}
      end

      def define_cast
        define_cast_group_singleton
        define_cast_singleton
        local_cast_methods = @cast_methods
        @klass.define_singleton_method(:cast_methods) { local_cast_methods }
        @klass.prepend Dryer::Cast::Memoize if @prepend
      end

      private

      def define_cast_group_singleton
        local_klass = @klass
        @klass.define_singleton_method :cast_group do |args = {}, &block|
          CastGroup.new(local_klass, args, &block).wrap
        end
      end

      def define_cast_singleton
        local_self = self
        local_cast_methods = @cast_methods
        # _memoize_storage = @_memoize_storage

        @klass.define_singleton_method(:cast) do |*macro_args|
          name = macro_args.shift
          options = macro_args.shift || {}
          constructor_args = [*options[:with]]
          access = local_self.send(:format_access, options)
          namespace = options[:namespace]
          memoize = options[:memoize] ? true : false
          camelized_name = local_self.__send__(:camelize, name.to_s)
          target_klass = [namespace, options.fetch(:to, camelized_name)].compact.join("::")

          method_type = options[:class_method] ? :define_singleton_method : :define_method

          __send__(method_type, name) do |*args|
            if memoize
              @_memoize_storage ||= {}
              @_memoize_storage[name] ||= {}
              constructor_key = frozen? ? object_id : constructor_args
              @_memoize_storage[name][constructor_key] ||= {}
              if @_memoize_storage[name][constructor_key].key?(args)
                @_memoize_storage[name][constructor_key][args]
              else
                @_memoize_storage[name][constructor_key][args] =
                  local_self.__send__(:eval_target, self, constructor_args, target_klass, *args)
              end
            else
              local_self.__send__(:eval_target, self, constructor_args, target_klass, *args)
            end
          end
          local_cast_methods[name] = { to: target_klass, with: constructor_args, memoize: memoize }
          __send__(access, name)
        end
      end

      def eval_target(caster, constructor_args, target_klass, *args)
        constructor_params = constructor_args.each_with_object({}) do |method, object|
          if method.class == Hash
            method.each_with_object(object) do |(method2, local_method), object2|
              object2[method2] = local_method == :self ? caster : caster.__send__(local_method)
            end
          else
            object[method] = caster.__send__(method)
          end
        end
        target_instance = Kernel.const_get(target_klass).new(constructor_params)

        if target_instance.method(:call).arity.zero?
          target_instance.call
        else
          target_instance.call(*args)
        end
      end

      def camelize(str)
        str.split("_").map(&:capitalize).join
      end

      def format_access(options)
        access = options[:access] ? [*options[:access]].last : :public
        access = access.to_s + "_class_method" if options[:class_method]
        access
      end
    end
  end
end
