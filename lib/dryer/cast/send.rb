module Dryer
  module Cast
    def self.base(root_module: nil)
      ::Dryer::Cast::Base.new(root_module)
    end

    class Base < Module
      attr_reader :base_module
      def initialize(base_module)
        @base_module = base_module
      end

      def included(klass)
        define_macro(klass)
      end

      def define_macro(klass)
        local_base_module = base_module
        klass.define_singleton_method :dryer_delegate do |*macro_args, &_macro_block|
          name = macro_args.shift
          options = macro_args.shift || {}
          explicit_klass = options[:class_name]

          define_method(name) do |*args, &block|
            implicit_klass = [local_base_module, name.to_s.classify].join("::")
            delegate_klass = explicit_klass ? explicit_klass : implicit_klass
            delegate_instance = delegate_klass.constantize.new(sender: self)

            if delegate_instance.method(:call).arity.zero?
              delegate_instance.call(&block)
            else
              delegate_instance.call(*args, &block)
            end
          end
        end
      end

    end
  end
end
