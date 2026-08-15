# frozen_string_literal: true

require "nextrb"
require_relative "./app/root"

class App < Nextrb::App
  @todos = [
    { "id" => 0, "text" => "make this app" },
    { "id" => 1, "text" => "don't go crazy" }
  ]

  class << self
    attr_accessor :todos
  end

  get "/", Root
  post "/todo" do |req, resp|
    ::App.todos << { "id" => ::App.todos.count, "text" => req.params["text"] }
    resp.redirect_back
  end
  delete "/todo/:id" do |req, resp|
    ::App.todos.delete_at(req.args["id"].to_i)
    resp.redirect_back
  end
end

Nextrb.run!(App.new)
