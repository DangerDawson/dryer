require "dryer/cast/cast_group"
require "dryer/cast/memoize"
module Dryer
  module Cast
    class << self
      def config(args = {})
        namespace = args.fetch(:namespace, nil)
        prepend = args.fetch(:prepend, true)
        with = args.fetch(:with, [])
        Dryer::Cast::Base.new(prepend: prepend, namespace: namespace, with: with)
      end

      def included(klass)
        construct = Dryer::Cast::Base.new
        construct.define_cast(klass)
      end
    end

    class Base < Module
      def initialize(prepend: true, namespace: nil, with: [])
        @prepend = prepend
        @namespace = namespace
        @with = [*with]
        @_memoize_storage = {}
        freeze
      end

      def included(klass)
        super(klass)
        define_cast(klass)
      end

      def define_cast(klass)
        define_cast_group_singleton(klass)
        define_cast_singleton(klass)
        klass.prepend Dryer::Cast::Memoize if @prepend
      end

      private

      def define_cast_group_singleton(klass)
        local_klass = klass
        klass.define_singleton_method :cast_group do |args = {}, &block|
          CastGroup.new(local_klass, args, &block).wrap
        end
      end

      # computes the class name completed with the correct namespace
      # if the to or namespace starts with :: e.g. ::Foobar then it ignores
      # everything before the ::Foobar
      def fetch_target_klass(default_namespace, namespace, to)
        target_klass = [default_namespace, namespace, to].compact.flatten
        target_klass_start_index = target_klass.rindex { |x| x.to_s.match(/^::/) } || 0
        reduced_target_klass = target_klass[target_klass_start_index, target_klass.size]
        reduced_target_klass.join("::")
      end

      def define_cast_singleton(klass)
        local_self = self
        default_with = @with
        default_namespace = @namespace

        klass.define_singleton_method(:cast) do |*macro_args|
          name = macro_args.shift
          options = macro_args.shift || {}
          constructor_args = [*options[:with]] + default_with
          access = local_self.send(:format_access, options)
          namespace = options[:namespace]
          prefix = options.fetch(:prefix, nil)
          memoize = options[:memoize] ? true : false
          camelized_name = local_self.__send__(:camelize, name.to_s)
          to = options.fetch(:to, camelized_name)
          target_klass = local_self.__send__(:fetch_target_klass, default_namespace, namespace, to)

          method_type = options[:class_method] ? :define_singleton_method : :define_method
          method_name = [prefix, name].compact.join("_")

          cast_methods = { name => { to: target_klass, with: constructor_args, memoize: memoize } }
          cast_methods.merge!(self.cast_methods) if respond_to?(:cast_methods)
          define_singleton_method(:cast_methods) { cast_methods }

          __send__(method_type, method_name) do |*args, &block|
            if memoize
              @_memoize_storage ||= {}
              @_memoize_storage[name] ||= {}
              constructor_key = frozen? ? object_id : constructor_args
              @_memoize_storage[name][constructor_key] ||= {}
              if @_memoize_storage[name][constructor_key].key?(args)
                @_memoize_storage[name][constructor_key][args]
              else
                @_memoize_storage[name][constructor_key][args] =
                  local_self.__send__(:eval_target, self, constructor_args, target_klass, *args, block)
              end
            else
              local_self.__send__(:eval_target, self, constructor_args, target_klass, *args, block)
            end
          end
          __send__(access, method_name)
        end
      end

      def eval_target(caster, constructor_args, target_klass, *args, block)
        constructor_params = constructor_args.each_with_object({}) do |method, object|
          if method.class == Hash
            method.each_with_object(object) do |(method2, local_method), object2|
              object2[method2] = local_method == :self ? caster : caster.__send__(local_method)
            end
          else
            object[method] = caster.__send__(method)
          end
        end

        # Ensure that we do not send over an empty {} if no args are specified
        target_klass = Kernel.const_get(target_klass)
        target_instance = if constructor_params.empty?
                            target_klass.new
                          else
                            target_klass.new(constructor_params)
                          end

        if target_instance.method(:call).arity.zero?
          target_instance.call(&block)
        else
          target_instance.call(*args, &block)
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
