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

class CasterSingleton
  include Dryer::Cast
  include ::Dryer::Construct
  construct

  cast_group do
    cast :cast_a, to: Target, singleton: true
  end
end

class Base
  include ::Dryer::Construct
  construct(:one, two: 2)
end

class Construct < Base
  construct(:three, four: 4)
end

class Construct2 < Base
  construct(:five, six: 6)
end

1000.times do
  Caster.new.cast_a
  Construct.new(one: 1, three: 3)
  Construct2.new(one: 1, five: 5)
end

GC.start
puts "Leaked Caster Objects: #{ObjectSpace.each_object(Caster).count}"
puts "Leaked Caster Singleton Objects: #{ObjectSpace.each_object(CasterSingleton).count}"
puts "Leaked Constructer Base Objects: #{ObjectSpace.each_object(Base).count}"
puts "Leaked Constructer Construct Objects: #{ObjectSpace.each_object(Construct).count}"
puts "Leaked Constructer Construct2 Objects: #{ObjectSpace.each_object(Construct2).count}"
