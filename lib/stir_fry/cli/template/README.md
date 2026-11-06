# Your new StirFry App

Let's get cooking!

## Getting started
- `bundle install` Install dependencies.
- `bundle exec puma` Run the web app at port 9292
- `open http://localhost:9292` Visit the site.

## App Layout

```
    - app/
        |- pages
            |- layout.rb # Layout component that wraps the other 2 pages
            |- home.rb # The root route.
            |- greet.rb # The page at the GET /greet route. It accepts a param.
        |- app.rb # The entrypoint the the app that defines the routes.
    - config.ru #  The rackup file meant to start the app.
```
