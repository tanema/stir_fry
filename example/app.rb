# frozen_string_literal: true

$LOAD_PATH << File.expand_path(__dir__)

require "nextrb"

# Manage loading your application yourself. We do not monkey patch anything, not
# even class resolution. It's vanilla ruby all the way down.
autoload :Todos, "app/todos"
autoload :Root, "app/root"
autoload :DB, "app/db"

# This is the root of the application, It maps out the routes and in your application
# it would handle setup, data connections, configurations, and any other app-wide
# concerns.
class App < Nextrb::App
  static File.join(__dir__, "public")
  get "/", Root
  post "/todo", Todos::List
  delete "/todo/:id", Todos::Todo
  put "/todo/:id/toggle", Todos::Todo
end

Nextrb.run!(App)
