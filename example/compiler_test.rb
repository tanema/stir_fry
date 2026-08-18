require "nextrb"

template = %(<div class="name" id = 'title' value=yes disabled></div>)

compiler = Nextrb::RBX::Compiler.new("test.tmpl", template)
html_elem = compiler.parse[0]
puts html_elem.members
