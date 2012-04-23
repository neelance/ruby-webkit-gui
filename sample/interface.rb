text "Interface Sample"

div align: :center do
  @label = span "aaa"
end
button "Get Color", onclick: -> { puts @label.style.color }
button "Get Style", onclick: -> { puts @label.style }
button "Set Color", onclick: -> { @label.style.color = "red" }
button "Get Text", onclick: -> { puts @label.text }
button "Set Text", onclick: -> { @label.text = "bbb" }
br

@input = input type: "text", value: "something"
button "Get Input Type", onclick: -> { puts @input.type }
button "Set Input Type", onclick: -> { @input.type = "hidden" }
button "Get Input Value", onclick: -> { puts @input.value }
button "Set Input Value", onclick: -> { @input.value = "nothing" }
br

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