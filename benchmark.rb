#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "dryer"
require "benchmark/ips"

class A
  include ::Dryer::Construct
  construct

  def call
    1
  end
end

class B
  include Dryer::Cast
  include ::Dryer::Construct
  construct

  cast :cast_a, to: A

  def direct_a
    A.new.call
  end
end

class C
  include ::Dryer::Construct
  def direct_a
    A.new.call
  end
end

Benchmark.ips do |bm|
  bm.report("pure_direct") { C.new.direct_a  }
  bm.report("direct") { B.new.direct_a  }
  bm.report("cast") { B.new.cast_a  }
end
