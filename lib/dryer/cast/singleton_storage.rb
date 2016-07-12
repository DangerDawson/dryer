require "concurrent"
module Dryer
  module Cast
    module SingletonStorage
      @@storage = ::Concurrent::Array.new

      def self.storage
        @@storage
      end

      def self.clear
        @@storage.each(&:clear)
      end

      def self.register
        hash = ::Concurrent::Hash.new
        @@storage << hash
        hash
      end
    end
  end
end
