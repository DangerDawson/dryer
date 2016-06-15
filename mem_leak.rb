#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "dryer"

class Target
  include ::Dryer::Construct
  construct

  def call
    1 + 1
  end
end

class Caster
  include Dryer::Cast
  include ::Dryer::Construct
  construct

  cast_group do
    cast :cast_a, to: Target
  end
end

1000.times do
  Caster.new.cast_a
end

GC.start
puts "Leaked Objects: #{ObjectSpace.each_object(Caster).count}"
