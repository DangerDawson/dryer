require "dryer/cast/cast_group"
require "dryer/cast/memoize"
require "dryer/cast/constantize"
require "dryer/shared/deep_freeze"
require "dryer/shared/singleton_storage"
module Dryer
  module Cast
    class << self
      def config(args = {})
        Dryer::Cast::Base.new(
          prepend:   args.fetch(:prepend, true),
          namespace: args.fetch(:namespace, nil),
          construct: args.fetch(:construct, []),
          with:      args.fetch(:with, []),
          singleton: args.fetch(:singleton, false)
        )
      end

      def included(klass)
        construct = Dryer::Cast::Base.new
        construct.define_cast(klass)
      end

      def clear_singleton_storage
        Dryer::Shared::SingletonStorage.clear
      end
    end

    class Base < Module
      using Dryer::Shared::DeepFreeze
      using Dryer::Cast::Constantize

      def initialize(prepend: true, namespace: nil, singleton: false, construct: [], with: [])
        @prepend = prepend
        @namespace = namespace
        @singleton = singleton
        @construct = [*construct]
        @with = [*with]
        @_singleton_storage = Dryer::Shared::SingletonStorage.register
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

      # Stolen from active suport
      def define_cast_group_singleton(klass)
        local_klass = klass
        klass.define_singleton_method :cast_group do |args = {}, &block|
          CastGroup.new(local_klass, args, &block).wrap
        end
      end

      def fetch_target_klass(default_namespace, options, name)
        camelized_name = camelize(name.to_s)
        to = options.fetch(:to, camelized_name)
        if options[:namespace!]
          [options[:namespace!], to]
        else
          [default_namespace, options[:namespace], to]
        end.compact.flatten.join("::")
      end

      def define_cast_singleton(klass)
        local_self = self
        default_with = @with
        default_construct = @construct
        default_namespace = @namespace
        default_singleton = @singleton

        klass.define_singleton_method(:cast) do |*macro_args|
          name = macro_args.shift
          options = macro_args.shift || {}
          constructor_args = [*options[:construct]] + default_construct

          with_args = options[:with!] ? [*options[:with!]] : [*options[:with]] + default_with

          access = local_self.send(:format_access, options)
          prefix = options.fetch(:prefix, nil)
          singleton = options.fetch(:singleton, default_singleton)
          memoize = options[:memoize] ? true : false

          target_klass = local_self.__send__(:fetch_target_klass, default_namespace, options, name)

          method_type = options[:class_method] ? :define_singleton_method : :define_method
          method_name = [prefix, name].compact.join("_")

          cast_methods = { name => { to: target_klass, construct: constructor_args, memoize: memoize, with: with_args } }
          cast_methods.merge!(self.cast_methods) if respond_to?(:cast_methods)
          define_singleton_method(:cast_methods) { cast_methods }

          __send__(method_type, method_name) do |*args, &block|
            parsed_args = local_self.__send__(:parse_args, self, with_args)
            args = local_self.__send__(:merge_args, args, parsed_args)

            call_target_args = [self, method_type, name, singleton, constructor_args, target_klass, *args, block]
            if memoize
              @_memoize_storage ||= {}
              constructor_key = frozen? ? object_id : constructor_args
              key = [name, constructor_key, args]
              unless @_memoize_storage.key?(key)
                @_memoize_storage[key] = local_self.__send__(:call_target, *call_target_args)
              end
              @_memoize_storage[key]
            else
              local_self.__send__(:call_target, *call_target_args)
            end
          end
          __send__(access, method_name)
        end
      end

      def build_target_instance(target_klass, caster, constructor_args)
        constructor_params = parse_args(caster, constructor_args)
        target_klass = target_klass.constantize
        if constructor_params.empty?
          target_klass.new
        else
          target_klass.new(constructor_params)
        end
      end

      def build_instance(target_klass, method_type, name, singleton, caster, constructor_args)
        if singleton
          key = [method_type, name]
          unless @_singleton_storage.key?(key)
            instance = build_target_instance(target_klass, caster, constructor_args)
            unless instance.deep_frozen?
              msg = "singleton error, unfrozen objects detected: #{instance.deep_unfreezable}"
              raise(Dryer::Shared::DeepFreeze::Error, msg)
            end
            @_singleton_storage[key] = instance
          end
          @_singleton_storage[key]
        else
          build_target_instance(target_klass, caster, constructor_args)
        end
      end

      def call_target(caster, method_type, name, singleton, constructor_args, target_klass, *args, block)
        target_instance = build_instance(target_klass, method_type, name, singleton, caster, constructor_args)
        begin
          target_arity = target_instance.method(:call).arity
          target_arity.zero? ? target_instance.call(&block) : target_instance.call(*args, &block)
        rescue ArgumentError => e
          msg = "class: #{target_klass}, called with: #{args}, but returned error: #{e.message}"
          raise(ArgumentError, msg)
        end
      end

      def parse_args(caster, args)
        args.each_with_object({}) do |method, object|
          if method.class == Hash
            method.each_with_object(object) do |(method2, local_method), object2|
              object2[method2] = local_method == :self ? caster : caster.__send__(local_method)
            end
          else
            object[method] = caster.__send__(method)
          end
        end
      end

      def merge_args(args, merge_args)
        args = args.dup
        if merge_args.any?
          args << if args.last.is_a?(Hash)
                    args.pop.merge(merge_args)
                  else
                    merge_args
                  end
        end
        args
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
