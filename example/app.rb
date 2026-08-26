# frozen_string_literal: true

$LOAD_PATH << File.expand_path("app", __dir__)

require "nextrb"
require "root"

DEFAULT_TODOS = [
  { "id" => 0, "text" => "make this app" },
  { "id" => 1, "text" => "don't go crazy" }
]

class App < Nextrb::App 
  @todos = DEFAULT_TODOS
  @next_id = 2
  class << self
    attr_accessor :todos, :next_id
  end

  static File.join(__dir__, "public")
  get "/", Root
  post "/todo", Todos::List
  delete "/todo/:id", Todos::Todo
  put "/todo/:id/toggle", Todos::Todo
end

Nextrb.run!(App)
