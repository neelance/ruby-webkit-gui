text "foo"
div align: :center do
  @label = span "abc"
  @input = input type: "text"
end

button "Test 1", onclick: -> { puts "yeah" }
button "Test 2", onclick: -> { @label.style.color = "red" }
button "Test 3", onclick: -> { puts @label.style.color }
button "Test 4", onclick: -> { puts @label.style }
button "Test 5", onclick: -> { puts @input.type }
button "Test 6", onclick: -> { @input.type = "hidden" }

@list = DynamicArray.new self
@table = table do
  @list.each do |entry|
    tr do
      td entry[:a]
      td entry[:b]
    end
  end
end

button "Add row", onclick: -> { @list << { a: rand(100), b: "test" } }