# frozen_string_literal: true

$LOAD_PATH << File.expand_path(__dir__)

require "bundler/setup"
require "stir_fry"

# Manage loading your application yourself. We do not monkey patch anything, not
# even class resolution. It's vanilla ruby all the way down.
autoload :Layout, "app/layout"
autoload :Root,   "app/root"
autoload :DB,     "app/db"
autoload :Todo,   "app/todo"
autoload :List,   "app/list"
autoload :Input,  "app/input"

# This is the root of the application, It maps out the routes and in your application
# it would handle setup, data connections, configurations, and any other app-wide
# concerns.
class App < StirFry::App
  static File.join(__dir__, "public")
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
