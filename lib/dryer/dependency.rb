require "dryer/construct/unfreeze"
require "dryer/construct/base_initialize"
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
    end

    # TODO: use singleton storage
    # TODO: check for unfrozen dependencies then barf

    class Base < Module
      def included(klass)
        build(klass)
      end

      def build(klass)
        klass.define_singleton_method(:dependencies) do |args|
          args.each do |method, dependency_klass|
            define_method(method) do
              dependency_klass.new
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
