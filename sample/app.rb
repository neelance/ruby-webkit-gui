$: << "../lib"
require "ruby_webkit_gui"

interface = WebKitInterface.new "interface.rb"
puts interface[:label]

interface[:table].append do
  
end

interface.run