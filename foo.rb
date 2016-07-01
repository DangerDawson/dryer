#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "dryer"
require 'pry'

class Base
  include ::Dryer::Construct.config()
  construct(:dave, base: "base")
  before_freeze do
    @base_freeze = "base_freeze"
  end
end

class One < Base
  construct(:optional, one: 1)
  construct(:optional2, three: 3)
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

class Dave
  def initialize(a)
    super()
    puts a
  end
end

class Dawson
  def initialize(a)
    super()
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
one = One.new(dave: "dave", optional: "optional", optional2: "optional2")
two = Two.new(dave: "dave")

puts "One ------------------------------"
puts one.instance_variables
puts "Two ------------------------------"
puts two.instance_variables
puts "------------------------------"

puts one.__send__(:base)
puts one.__send__(:one)
puts one.__send__(:optional)
puts one.__send__(:optional2)
#puts Two.new.__send__(:base)
#puts Two.new.__send__(:two)
#puts Two.new.__send__(:one)
#puts Two.new.foobar
#puts Two.foobar
