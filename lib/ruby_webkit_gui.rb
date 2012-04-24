require "ffi"

require "ruby_webkit_gui/ffi/glib"
require "ruby_webkit_gui/ffi/gtk"
require "ruby_webkit_gui/ffi/webkit"

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
  
  class DOMHTMLInputElement
    include DOMNodeWrappers
    include DOMEventTargetWrappers
    include DOMElementWrappers
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
  
  class DOM < Wrapper
    attr_reader :callbacks
    
    def initialize(native)
      super
      @callbacks = []
    end
    
    def method_missing(name, *args, &block)
      @native.send name, *args, &block
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
      @dom = dom
    end
    
    def style
      Style.new @native.get_style
    end
    
    def text
      @native.get_text_content
    end
    
    def text=(content)
      @native.set_text_content content, nil
    end
    
    def method_missing(name, *args, &block)
      return super if [:to_ary].include? name
      
      if name.to_s.end_with? "="
        if name.to_s.start_with? "on"
          block ||= args.first
          function = FFI::Function.new :void, [], &block
          @dom.callbacks << function # avoid garbage collection
          @native.add_event_listener name.to_s[2..-2], function, 0, nil
        else
          @native.set_attribute name.to_s[0..-2], args.first.to_s, nil
        end
        args.first
      else
        @native.get_attribute name.to_s
      end
    end
  end
  
  class InputElement < Element
    def initialize(*args)
      super
      @native = WebKit::DOMHTMLInputElement.new @native.to_ptr
    end
    
    def value
      @native.get_value
    end
    
    def value=(content)
      @native.set_value content
    end
  end
  
  class DynamicArray
    def initialize(context)
      @context = context
      @targets = []
      @content = []
    end
    
    def each(&block)
      @targets << [@context.current_target, block]
    end
    
    def <<(entry)
      @content << entry
      @targets.each do |(target, block)|
        @context.with_target target do
          @context.instance_exec(entry, &block)
        end
      end
    end
  end
  
  class DSLContext
    attr_reader :current_target
    
    def initialize(dom)
      @dom = dom
      html = dom.get_first_child
      head = html.get_first_child
      body = head.get_next_sibling
      @current_target = Node.new body
    end
    
    def with_target(target)
      previous_target = @current_target
      @current_target = target
      yield
      @current_target = previous_target
    end
    
    def text(content)
      node = @dom.create_text_node content
      current_target << node
      node
    end
    
    def method_missing(name, *args)
      element = case name
      when :input
        InputElement.new @dom, name
      else
        Element.new @dom, name
      end
      current_target << element
      with_target element do
        args.each do |arg|
          case arg
          when Hash
            arg.each do |attribute, value|
              element.__send__ "#{attribute}=", value
            end
          else
            text arg.to_s
          end
        end
        yield if block_given?
      end
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
    
    @dom = DOM.new @web_view.get_dom_document
    @context = DSLContext.new @dom
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