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

class CasterWithRefine
  include Dryer::Cast
  include ::Dryer::Construct
  construct
  using cast_refine(Target) {
    cast :cast_a, to: Target
  }

  def refine
    Target.new.cast_a
  end
end


1000.times do
  Caster.new.cast_a
  CasterWithRefine.new.refine
end

GC.start
puts "Leaked Caster Objects: #{ObjectSpace.each_object(Caster).count}"
puts "Leaked CasterWithRefine Objects: #{ObjectSpace.each_object(CasterWithRefine).count}"
