# Nextrb
A small, simple web framework that lets you enjoy ruby with a JSX type flavour. 

## Installation

`gem install 'nextrb'`

## Usage
An example project could look like this. The templating leverages a weird feature 
of ruby with the `__END__` data sections [ref](https://til.hashrocket.com/posts/17787bf181-rubys-end)
to inline templates in the same file and be able to parse them where they are. 
I have not yet figured out how to add syntax highlighting for it but it is a start.

### layout.rb

```ruby
class Layout < Nextrb::Component
end

__END__
<html>
  <body>
    { yield }
  </body>
</html>
```

### home.rb

```ruby
class Home < Nextrb::Component
  def name
    "Bobby"
  end
end

__END__
<Layout>
    <h1>Hello {name}</h1>
</Layout>
```

### app.rb

```
require "layout"
require "home"

class App < Nextrb::App 
  # Render the components
  get "/", Home
  # Raw API call
  get "/hello/:name" {|req,resp| resp.text("Hello #{req.args["name"]}", :ok) }
end

Nextrb.run!(App)
```

### Multiple Inline templates
Multiple templates can be defined in the same file as well with an addition of 
an `@@` label. This idea was taken from [Sinatra](#acknowledgment).

```ruby
class Layout < Nextrb::Component
end
class Home < Nextrb::Component
end

__END__
@@Layout
<html>
  <body>{ yield }</body>
</html>

@@Home
<Layout><h1>Hello Bobby</h1></Layout>
```

## Development

After checking out the repo, 

- run `bundle install` to install dependencies. 
- run `rake` to run the specs and rubocop. 
- run `rake run` to run the example todos app. 

## Releasing

To release a new version

- update the version number in `version.rb`
- run `bundle exec rake release`, which will create a git tag for the version
- push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Further Reading

- [Project Design Conventions](CONVENTIONS.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [License](https://opensource.org/licenses/MIT)

## Acknowledgment 
These are the projects that I took both inspiration and code chunks from. Since I 
wanted an interface a lot like Sinatra, I used their codebase heavily for routing.
Also since I wanted a reactjs markdown style, I used rbexy initially but then 
ended up re-writing a lot of it to remove all rails integrations and I ended up 
rewriting to more of a classical recursive descent parser just because it would be
more comfortable for me to work on.

- [Sinatra](https://github.com/sinatra/sinatra/)
- [Rbexy](https://github.com/patbenatar/rbexy)
- [Rack](https://github.com/rack/rack)
