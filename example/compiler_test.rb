require "nextrb"


template = <<~RBX
<li id={list_key}>
  <div class="view">
    <input type="checkbox" {**checkbox_attrs} />
    <label>{ todo["text"] }</label>
    <button class="destroy" 
            hx-delete={ "/todo/{ todo["id"] }" } 
            hx-target="#todo-list" 
            hx-swap="innerHTML"></button>
  </div>
</li>
RBX

puts Nextrb::RBX.compile(__FILE__, template)
