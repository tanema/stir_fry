# frozen_string_literal: true

require "nextrb"

class Banner < Nextrb::Component # :nodoc:
  def initialize(name:)
    @name = name
  end
end

class Page < Nextrb::Component # :nodoc:
  def about_path
    "/home/about"
  end

  def click_title
    "Click me"
  end

  def link_to(_path, &)
    yield
  end
end

class App < Nextrb::App
  get "/", Page
end

Nextrb.run!(App.new)

__END__
@@Page
<!DOCTYPE html>
<html>
  <body>
    <Banner name="bobby">
      <p>Welcome to nextrb, marrying the nice parts of nextjs with minimal ruby.</p>
      <Button to={ about_path }>Learn more</Button>
    </Banner>
    <ul>
      {[1, 2, 3].map { |n| <li>{n}</li> }}
    </ul>
    {link_to about_path do
      <span>{click_title}</span>
    end}
  </body>
</html>

@@Banner
<div>
  <h1>Hello { @name }</h1>
  { yield }
</div>
