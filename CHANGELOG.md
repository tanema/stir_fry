## [Unreleased]
- Fixed / paths inside a scope so scope "/todo" => post "/" ends up being simply "/todo"
- Shared RoutesList component to show routes on the routes page and not_found page.
- Display all routes instead of just user routes.
- Added a welcome page for when the app has no defined routes.
- Allow to set custom logger
- Added a default favicon.ico
- Added ability to add description to routes.
- Added mvp app example, all in a single config.ru
- Added a new command to the cli to generate a new project 
- Simplified the run command

## [0.1.5] - 2026-09-07

- Fixed an autoload issue on VERSION constants.

## [0.1.4] - 2026-09-07

- Still just trying to get the bin working

## [0.1.3] - 2026-09-07

- Added deps for `stirfry` cli command to gemspec so it is usable

## [0.1.2] - 2026-09-07

- Added a `stirfry` cli command to gemspec files so it is usable

## [0.1.1] - 2026-09-07

- Added a `stirfry` cli command for easy development running.

## [0.1.0] - 2026-09-06

Initial release of the whole framework including:

- Rack compatible App to run the app server in a way that is easy to use.
- Components for reacting to routes.
- Request & Response helpers
