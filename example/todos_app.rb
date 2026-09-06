#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << File.expand_path(__dir__)

require "bundler/setup"
require "nextrb"

# namespace for this app
module TodosApp
  # Manage loading your application yourself. We do not monkey patch anything, not
  # even class resolution. It's vanilla ruby all the way down.
  autoload :Layout, "todos_app/layout"
  autoload :Root,   "todos_app/root"
  autoload :DB,     "todos_app/db"
  autoload :Todo,   "todos_app/todo"
  autoload :List,   "todos_app/list"
  autoload :Input,  "todos_app/input"

  # This is the root of the application, It maps out the routes and in your application
  # it would handle setup, data connections, configurations, and any other app-wide
  # concerns.
  class App < Nextrb::App
    static File.join(__dir__, "todos_app/public")
    get "/", Root
    # Resource path scope so every path inside `scope` will have the /todo prefix on it.
    scope "/todo" do
      post "/", List
      delete "/:id", Todo
      put "/:id/toggle", Todo
    end
  end

  # Setup the Database
  DB.migrate!
end

# Run The app
Nextrb.run!(TodosApp::App)
