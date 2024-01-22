#!/usr/bin/env ruby
#
# Put description here
#

require 'swig_assert'

require 'director_min'

class MinCallback < Director_min::Callback
  def run()
    return true
  end
end

callback = MinCallback.new()
caller = Director_min::Caller.new(callback)
raise RuntimeError, "Should return true" unless caller.call()
