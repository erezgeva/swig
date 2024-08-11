begin
  require 'good'
rescue LoadError => e
  print "#{e.to_s}\n"
  print "File: #{e.path}\n"
end
