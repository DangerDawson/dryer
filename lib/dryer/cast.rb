require "dryer/cast/base"
require "dryer/cast/target"

module Dryer
  module Cast
    def self.base
      ::Dryer::Cast::Base.new
    end

    def self.target(*args)
      ::Dryer::Cast::Target.new(args)
    end
  end
end
