# frozen_string_literal: true

require "nextrb"

class Banner < Nextrb::Component
  def initialize(name:)
    @name = name
  end
end

class Page < Nextrb::Component
  def about_path
    "/home/about"
  end
end

puts Banner.compiled_template
# puts Page.new.render

puts Banner.new(name: "bobby").render do
  @output_buffer.safe_concat('<p>Welcome to nextrb, marrying the nice parts of nextjs with minimal ruby.</p> <Button to="')
  @output_buffer.concat("test")
  @output_buffer.safe_concat('">Learn more</Button>')
end

class Test
  def try_it
    instance_eval("puts yield", __FILE__, __LINE__)
  end
end

# Test.new.try_it { puts "got it" }

__END__
@@Page
<!DOCTYPE html>
<html>
  <body>
    <Banner name="bobby">
      <p>Welcome to nextrb, marrying the nice parts of nextjs with minimal ruby.</p>
      <Button to={about_path}>Learn more</Button>
    </Banner>
  </body>
</html>

@@Banner
<div>
  <h1>Hello {@name}</h1>
  {yield}
</div>
