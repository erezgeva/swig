#!/usr/bin/env ruby
#
# Put description here
#
# 
# 
# 
#

require 'swig_assert'

begin
  require 'import_fragments'
#rescue LoadError => e
rescue Exception => e
  # due to missing import_fragments_a
  puts "Error: #{e.message}"
# exception_file = e.respond_to?(:path) ? e.path : e.to_s.sub(/.* -- /, '')
end

# swig_assert(exception_file == "import_fragments_a",
#             msg: "Loading should have failed due to missing 'import_fragments_a'")

