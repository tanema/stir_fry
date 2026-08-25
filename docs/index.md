# Nextrb

## What this framework is designed for
- Make a webapp that acts like a normal ruby app. Managing requires/autoloads. 
- The least amount of magic possible. Developers should only need to look up 
  documentation for ruby and not the framework.
- Convention over configuration. No configuration unless really needed.
- Views that act like React but on the backend. We can describe a view and it's 
  behaviour all in one.
- Make it easy for htmx usage but do not make it required.

## What this framework will not do
- Manage datastores.
- Manage configuration will have the least amount of configuration and default to overrides.
- Manage layouts. It is up to the dev to decide exactly what is returned. This is for easy htmx usage.

## Design points.
- Single `Nextrb::App` that runs as the server
- Single `Nextrb::Server` running, managed by nextrb
- Each request handled by a `Nextrb::Component`. 
    - Component Class automatically rendered.
    - Verb methods on classes to allow for handling a specific verb
    - Proc optional but not recommended
- Component consists of a `Nextrb::Component` inherited class and a template at the 
  end of the file with `__END__`, rendered with `RBX` a `jsx` style markup.
- Ideally the whole page is rendered then only partials replaced with htmx
- Recommendations
    - HTMX
    - DryRb https://hanakai.org/dry
    - smart_properties

## Todos

- Rename? I don't like tying myself to preconceived notions.
- File serving HTTP_IF_MODIFIED_SINCE
- rack-session
- rack-protection
- update example with sqlite
- middleware
- Config
    - Error handlers


```ruby
builder1 = Rack::Builder.new
builder1.use( ... )
builder1.run(app_klass1)

builder2 = Rack::Builder.new
builder2.use( ... )
builder2.run(app_klass2)
 
cascade = Rack::Cascade.new(builder1, builder2)
Rackup::Handler.default.run(cascade)
```
