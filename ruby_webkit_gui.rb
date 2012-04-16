require "ffi/glib"
require "ffi/gtk"
require "ffi/webkit"

module GLIB
  def self.signal_connect(instance, detailed_signal, c_handler, data)
    signal_connect_data instance, detailed_signal, c_handler, data, nil, 0
  end
end

module WebKit
  class DOMDocument
    include DOMNodeWrappers
  end
  
  class DOMElement
    include DOMNodeWrappers
    include DOMEventTargetWrappers
  end
end

GTK.init nil, nil

class WebKitInterface
  class Wrapper
    def initialize(native)
      @native = native
    end
    
    def to_ptr
      @native.to_ptr
    end
  end
  
  class Node < Wrapper
    def <<(child)
      @native.append_child child, nil
    end
  end
  
  class Element < Node
    class Style < Wrapper
      def method_missing(name, *args, &block)
        return super if [:to_ary].include? name
        if name.to_s.end_with? "="
          WebKit.dom_css_style_declaration_set_property @native, name.to_s[0..-2], args.first, "", nil
        else
          WebKit.dom_css_style_declaration_get_property_value @native, name.to_s
        end
      end
      
      def to_s
        WebKit.dom_css_style_declaration_get_css_text @native
      end
    end
    
    def initialize(dom, name)
      super dom.create_element(name.to_s, nil)
    end
    
    def style
      Style.new @native.get_style
    end
    
    def method_missing(name, *args, &block)
      if name.to_s.end_with? "="
        if name.to_s.start_with? "on"
          @native.add_event_listener name.to_s[2..-2], FFI::Function.new(:void, [], &(block || args.first)), 0, nil
        else
          @native.set_attribute name.to_s[0..-2], args.first.to_s, nil
        end
        args.first
      else
        super
      end
    end
  end
  
  class DSLContext
    def initialize(dom)
      @dom = dom
      html = dom.get_first_child
      head = html.get_first_child
      body = head.get_next_sibling
      @stack = [Node.new(body)]
    end
    
    def text(content)
      node = @dom.create_text_node content
      @stack.last << node
      node
    end
    
    def method_missing(name, *args, &block)
      element = Element.new @dom, name
      @stack.last << element
      @stack.push element
      args.each do |arg|
        case arg
        when String
          text arg
        when Hash
          arg.each do |attribute, value|
            element.__send__ "#{attribute}=", value
          end
        end
      end
      yield if block_given?
      @stack.pop
      element
    end    
  end
  
  def initialize(filename)
    @window = GTK.window_new :toplevel
    GTK.window_set_default_size @window, 800, 600
    
    callback = FFI::Function.new(:void, [:pointer, :pointer]) { GTK.main_quit }
    GLIB.signal_connect @window, "destroy", callback, nil
    
    @web_view = WebKit::WebView.new WebKit.web_view_new
    scrolled_window = GTK.scrolled_window_new nil, nil
    GTK.container_add scrolled_window, @web_view
    GTK.container_add @window, scrolled_window
    
    @context = DSLContext.new @web_view.get_dom_document
    @context.instance_eval File.read(filename), filename, 1
  end
  
  def [](name)
    @context.instance_variable_get "@#{name}"
  end
  
  def run
    GTK.widget_grab_focus @web_view
    GTK.widget_show_all @window
    GTK.main
  end
end