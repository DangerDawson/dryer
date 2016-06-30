#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "dryer"
require 'pry'

class Base
  include ::Dryer::Construct.config()
  #include ::Dryer::Construct.config(freeze: false)
  construct(base: "base")
  before_freeze do
    @base_freeze = "base_freeze"
  end
end

class One < Base
  construct(one: 1)
  before_freeze do
    @one_freeze = "one_freeze"
  end
end

class Two < Base
  construct(two: 2)
  before_freeze do
    @two_freeze = "two_freeze"
  end
end

#class AnotherBase < Module
#  def self.included
#    puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#  end
#end

#class AnotherTwo < Module
#
#  def included(model)
#    puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#  end
#end
#
#class Three
#  include AnotherTwo.new()
#end

#puts AnotherTwo.new
#puts Three.new

puts "One ------------------------------"
puts One.new.instance_variables
puts "Two ------------------------------"
puts Two.new.instance_variables

#puts One.new.__send__(:base)
#puts One.new.__send__(:one)
#puts Two.new.__send__(:base)
#puts Two.new.__send__(:two)
#puts Two.new.__send__(:one)
#puts Two.new.foobar
#puts Two.foobar
