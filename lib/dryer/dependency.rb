require "dryer/shared/singleton_storage"
require "dryer/shared/deep_freeze"
module Dryer
  module Dependency
    class << self
      def config(_args = {})
        Dryer::Dependency::Base.new
      end

      def included(klass)
        dependency = Dryer::Dependency::Base.new
        dependency.build(klass)
      end

      def clear_singleton_storage
        Dryer::Shared::SingletonStorage.clear
      end
    end

    class Base < Module
      using Dryer::Shared::DeepFreeze

      def initialize
        @_singleton_storage = Dryer::Shared::SingletonStorage.register
        freeze
      end

      def included(klass)
        build(klass)
      end

      def build(klass)
        singleton_storage = @_singleton_storage
        klass.define_singleton_method(:dependencies) do |args|
          args.each do |method, dependency_klass|
            define_method(method) do
              unless singleton_storage.key?(method)
                instance = dependency_klass.new
                unless instance.deep_frozen?
                  msg = "singleton error, unfrozen objects detected: #{instance.deep_unfreezable}"
                  raise(Dryer::Shared::DeepFreeze::Error, msg)
                end
                singleton_storage[method] = instance
              end
              singleton_storage[method]
            end
            private method
          end
          define_singleton_method(:get_dependencies) do
            args
          end
        end
      end
    end
  end
end
