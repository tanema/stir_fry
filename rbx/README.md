# RBX
A ruby templating language similar to JSX

```ruby
class Layout
  include RBX::Component
end

class Home 
  include RBX::Component

  attr_reader :name

  def initializer(name:)
    @name = name
  end
end

puts Home.new(name: "Bobby").render()

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
