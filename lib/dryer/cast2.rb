require "dryer/cast/cast_group"
require "dryer/cast/memoize"
require "dryer/cast/deep_freeze"
require "dryer/cast/constantize"
module Dryer
  module Cast2
    class << self
      def config(args = {})
        Dryer::Cast2::Base.new(
          prepend:   args.fetch(:prepend, true),
          namespace: args.fetch(:namespace, nil),
          with:      args.fetch(:with, []),
        )
      end

      def included(klass)
        construct = Dryer::Cast2::Base.new
        construct.define_cast(klass)
      end
    end

    class Base < Module
      using Dryer::Cast::Constantize

      def initialize(prepend: true, namespace: nil, with: [])
        @prepend = prepend
        @namespace = namespace
        @with = [*with]
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
          Dryer::Cast::CastGroup.new(local_klass, args, &block).wrap
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
        default_namespace = @namespace

        klass.define_singleton_method(:cast2) do |*macro_args|
          name = macro_args.shift
          options = macro_args.shift || {}

          with_args = options[:with!] ? [*options[:with!]] : [*options[:with]] + default_with

          access = local_self.send(:format_access, options)
          prefix = options.fetch(:prefix, nil)
          memoize = options[:memoize] ? true : false

          target_klass = local_self.__send__(:fetch_target_klass, default_namespace, options, name)

          method_type = options[:class_method] ? :define_singleton_method : :define_method
          method_name = [prefix, name].compact.join("_")

          cast_methods = { name => { to: target_klass, memoize: memoize, with: with_args } }
          cast_methods.merge!(self.cast_methods) if respond_to?(:cast_methods)
          define_singleton_method(:cast_methods) { cast_methods }

          __send__(method_type, method_name) do |*args, &block|
            parsed_args = local_self.__send__(:parse_args, self, with_args)
            target_args = local_self.__send__(:merge_args, args, parsed_args)

            call_target_args = [self, target_klass, *target_args, block]

            if memoize
              @_memoize_storage ||= {}
              key_suffix = frozen? ? object_id : target_args
              key = [name, key_suffix]
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

      def build_target_instance(target_klass, caster, target_args)
        puts "TAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        puts target_args.inspect
        target_klass = target_klass.constantize
        if target_args.empty?
          target_klass.new
        else
          target_klass.new(*target_args)
        end
      end

      def call_target(caster, target_klass, *target_args, block)
        puts "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK"
        puts target_klass.inspect
        puts "IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
        target_instance = build_target_instance(target_klass, caster, target_args)
        puts target_instance.inspect
        begin
          target_instance.call(&block)
        rescue ArgumentError => e
          msg = "class: #{target_klass}, called with: #{target_args}, but returned error: #{e.message}"
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
