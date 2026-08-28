# frozen_string_literal: true

$LOAD_PATH << File.expand_path("app", __dir__)
 
require "nextrb"
require "root"
require "db"

class App < Nextrb::App 
  static File.join(__dir__, "public")
  get "/", Root
  post "/todo", Todos::List
  delete "/todo/:id", Todos::Todo
  put "/todo/:id/toggle", Todos::Todo
end

Nextrb.run!(App)
