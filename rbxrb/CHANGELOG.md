## [Unreleased]

## [0.1.0] - 2026-09-06

Initial release with support for

- Parsing templates
- Resolving tagnames to RBX::Component classes
- Compiling to HTML
- Auto-defining `render` on RBX::Components that will find the template, compile it
  and define a ruby method on the component of the resulting ruby.
