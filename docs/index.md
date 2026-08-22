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
- Manage configuration.
- Manage layouts. It is up to the dev to decide exactly what is returned. 
  This is for easy htmx usage.

## Design points.
- Single `Nextrb::App` that runs as the server
- Single `Nextrb::Server` running, managed by nextrb
- Each request handled by a `Nextrb::Component`. 
    - Component Class automatically rendered.
    - Verb methods on classes to allow for handling a specific verb
    - Proc optional but not recommended
- Component consists of a `Nextrb::Component` inherited class and a template at the 
  end of the file with `__END__`, rendered with `Nextrb::RBX` a `jsx` style markup.
- Ideally the whole page is rendered then only partials replaced with htmx

## Todos

- [ ] Rename? I don't like tying myself to preconceived notions.
- [x] Improve/rewrite lexer/parser so that error messages can be clearer.
- [x] Class.[verb] for handling specific requests.
- [ ] Server error handling / pages.
- [x] check templates are not reused when the templates are not labelled
- [x] HTML escaping has all been removed `Rack::Utils.escape_html`
- [ ] File serving HTTP_IF_MODIFIED_SINCE
