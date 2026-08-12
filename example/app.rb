require "nextrb"

template = %(<html>
  <body>
    hello world
  </body>
</html>
)

puts Nextrb::RBX.parse(template)
