text "foo"
div align: :center do
  @label = span "abc"
end
button "Test 1", onclick: -> { puts "yeah" }
button "Test 2", onclick: -> { @label.style.color = "red" }
button "Test 3", onclick: -> { puts @label.style.color }
button "Test 4", onclick: -> { puts @label.style }