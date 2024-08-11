begin
  require 'good'
rescue LoadError => e
  print "#{e.to_s}\n"
end
