Design
######

- Single `Nextrb::App` that runs as the server
    - App manages data store connections
    - App manages config for endpoints
- Single `Nextrb::Server` running
- Each request is handled by an `Nextrb::Action`
- Each endpoint... unknown
    - Component with layout
    - Once whole page is rendered then only partials replaced with htmx
- Component consists of a `Nextrb::Component` inherited class and a template at the end of the file with `__END__`
    - component is rendered with `Nextrb::RBX`
