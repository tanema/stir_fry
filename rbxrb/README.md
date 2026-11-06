# RBX
A ruby templating language similar to JSX

```ruby
require "bundler/setup"
require "rbx"

class Layout
  include RBX::Component
end

class Home 
  include RBX::Component

  attr_reader :name

  def initialize(name:)
    @name = name
  end
end

puts RBX.render(Home, name: "Bobby")
# OR Home.new(name: "Bobby").render

__END__
@@Layout
<html>
  <body>{ yield }</body>
</html>

@@Home
<Layout>
  <h1>Hello { name }</h1>
</Layout>
```
