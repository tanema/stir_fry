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
- Each request handled by a component. 
    - Proc optional but not recommended
    - Verb methods on classes to allow for handling a specific verb
- Ideally the whole page is rendered then only partials replaced with htmx
- Component consists of a `Nextrb::Component` inherited class and a template at the 
  end of the file with `__END__`, rendered with `Nextrb::RBX` a `jsx` style markup.

## Todos

- [ ] tag_kwargs only works on splats, it should spread normal tag values as well.
- [ ] Rename? I don't like tying myself to preconceived notions.
- [ ] Improve/rewrite lexer/parser so that error messages can be clearer.
- [ ] Component resolver should just assume capital tag names are supposed to be classes.
- [x] Class.[verb] for handling specific requests.
- [ ] Server error handling / pages.
- [ ] check templates are not reused when the templates are not labelled
- [ ] HTML escaping has all been removed `Rack::Utils.escape_html`
- [ ] File serving HTTP_IF_MODIFIED_SINCE
