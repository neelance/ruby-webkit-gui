task :generate_ffi do
  require "ffi_gen"
  
  FFIGen.generate(
    module_name:   "GLIB",
    ffi_lib:       "gobject-2.0",
    headers:       ["glib-object.h", /(gtype|gsignal)\.h/],
    cflags:        `pkg-config --cflags gobject-2.0`.split,
    prefixes:      ["g_", "G_"],
    blacklist:     ["_g_signals_destroy"],
    output:        "ffi/glib.rb"
  )
  
  FFIGen.generate(
    module_name:   "GTK",
    ffi_lib:       "gtk-3",
    headers:       ["gtk/gtk.h", /(gtkmain|gtkwindow|gtkwidget|gtkcontainer|gtkscrolledwindow|gtkenums)\.h/],
    cflags:        `pkg-config --cflags gtk+-3.0`.split,
    prefixes:      ["gtk_", "_Gtk", "GTK_"],
    blacklist:     ["_gtk_scrolled_window_get_scrollbar_spacing"],
    output:        "ffi/gtk.rb"
  )
  
  FFIGen.generate(
    module_name:   "WebKit",
    ffi_lib:       "webkitgtk-3.0",
    headers:       ["webkit/webkit.h", /webkit\/.*\.h/],
    cflags:        `pkg-config --cflags webkitgtk-3.0`.split,
    prefixes:      ["webkit_", "_WebKit"],
    blacklist:     ["webkit_check_version"],
    output:        "ffi/webkit.rb"
  )
  
end
