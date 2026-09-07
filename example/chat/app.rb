# frozen_string_literal: true

# This example does *not* work properly with WEBrick or other
# servers that are not concurrent.

$LOAD_PATH << File.expand_path(__dir__)
require "bundler/setup"
require "stir_fry"

# Manage loading your application yourself. We do not monkey patch anything, not
# even class resolution. It's vanilla ruby all the way down.
autoload :Layout, "app/layout"
autoload :Chat,   "app/chat"
autoload :Login,  "app/login"
autoload :ConnectionManager, "app/connection_manager"

# This is the root of the application, It maps out the routes and in your application
# it would handle setup, data connections, configurations, and any other app-wide
# concerns.
class App < StirFry::App
  use_session secret: "_super_super_secret_secret_secure_secure_secret_secret_which_is_secure_"
  static File.join(__dir__, "public")
  get "/", Chat
  post "/", Chat
  get "/login", Login
  post "/login", Login
  get "/stream", ConnectionManager
end

ConnectionManager.listen_for_messages!
