require "ruby_webkit_gui"

interface = WebKitInterface.new "interface.rb"
puts interface[:label]
interface.run