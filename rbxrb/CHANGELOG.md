## [Unreleased]
- Added `RBX.render` helper method.
- Fixes for more robust tag parsing that allows for less than signs to be used in expressions and plain text.
- More flexible tag option marshaller.
- Simplified script tag skipping.

## [0.1.5] - 2026-09-07
## [0.1.4] - 2026-09-07
## [0.1.3] - 2026-09-07
## [0.1.2] - 2026-09-07
## [0.1.1] - 2026-09-07
## [0.1.0] - 2026-09-06

Initial release with support for

- Parsing templates
- Resolving tagnames to RBX::Component classes
- Compiling to HTML
- Auto-defining `render` on RBX::Components that will find the template, compile it
  and define a ruby method on the component of the resulting ruby.
