require "dryer/cast/cast_group"
require "dryer/cast/memoize"
module Dryer
  module Cast
    class << self
      def config(args = {})
        namespace = args.fetch(:namespace, nil)
        prepend = args.fetch(:prepend, true)
        construct = args.fetch(:construct, [])
        with = args.fetch(:with, [])
        Dryer::Cast::Base.new(
          prepend: prepend, namespace: namespace, construct: construct, with: with
        )
      end

      def included(klass)
        construct = Dryer::Cast::Base.new
        construct.define_cast(klass)
      end
    end

    class Base < Module
      def initialize(prepend: true, namespace: nil, construct: [], with: [])
        @prepend = prepend
        @namespace = namespace
        @construct = [*construct]
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

      # Stolen from active suport
      def constantize(camel_cased_word)
        names = camel_cased_word.split("::".freeze)

        # Trigger a built-in NameError exception including the ill-formed constant in the message.
        Object.const_get(camel_cased_word) if names.empty?

        # Remove the first blank element in case of '::ClassName' notation.
        names.shift if names.size > 1 && names.first.empty?

        names.inject(Object) do |constant, name|
          if constant == Object
            constant.const_get(name)
          else
            candidate = constant.const_get(name)
            next candidate if constant.const_defined?(name, false)
            next candidate unless Object.const_defined?(name)

            # Go down the ancestors to check if it is owned directly. The check
            # stops when we reach Object or the end of ancestors tree.
            constant = constant.ancestors.inject do |const, ancestor|
              break const    if ancestor == Object
              break ancestor if ancestor.const_defined?(name, false)
              const
            end

            # owner is in Object, so raise
            constant.const_get(name, false)
          end
        end
      end

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

        klass.define_singleton_method(:cast) do |*macro_args|
          name = macro_args.shift
          options = macro_args.shift || {}
          constructor_args = [*options[:construct]] + default_construct

          with_args = options[:with!] ? [*options[:with!]] : [*options[:with]] + default_with

          access = local_self.send(:format_access, options)
          prefix = options.fetch(:prefix, nil)
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

            if memoize
              @_memoize_storage ||= {}
              @_memoize_storage[name] ||= {}
              constructor_key = frozen? ? object_id : constructor_args
              @_memoize_storage[name][constructor_key] ||= {}
              if @_memoize_storage[name][constructor_key].key?(args)
                @_memoize_storage[name][constructor_key][args]
              else
                @_memoize_storage[name][constructor_key][args] =
                  local_self.__send__(:call_target, self, constructor_args, target_klass, *args, block)
              end
            else
              local_self.__send__(:call_target, self, constructor_args, target_klass, *args, block)
            end
          end
          __send__(access, method_name)
        end
      end

      def call_target(caster, constructor_args, target_klass, *args, block)
        constructor_params = parse_args(caster, constructor_args)

        # Ensure that we do not send over an empty {} if no args are specified
        target_klass = constantize(target_klass)

        target_instance = if constructor_params.empty?
                            target_klass.new
                          else
                            target_klass.new(constructor_params)
                          end

        begin
          target_arity = target_instance.method(:call).arity
          target_arity.zero? ? target_instance.call(&block) : target_instance.call(*args, &block)
        rescue ArgumentError => e
          raise ArgumentError.new(
            "class: #{target_klass}, called with: #{args}, but returned error: #{e.message}"
          )
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
