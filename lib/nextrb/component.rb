# frozen_string_literal: true

module Nextrb
  # Component is a request/response view handler. It can be a plain class with a
  # template inlined in the same file but it can also have the request class methods
  # such as `self.get`, `self.post`, `self.delete` ect. so that specific requests
  # can have more rich handling and different views can be returned.
  #
  # Example:
  #
  #
  # ```ruby
  # module Todos
  #   class Todo < Nextrb::Component
  #     attr_reader :todo
  #
  #     class << self
  #       # PUT /todo/:id/toggle
  #       def put(req, resp)
  #         todo = ::App.todos.find { |t| t["id"] == req.args["id"].to_i }
  #         todo["done"] = !todo["done"]
  #         resp.ok(new(todo: todo)) # Return a Todo view
  #       end
  #
  #       # DELETE /todo/:id
  #       def delete(req, resp)
  #         ::App.todos.delete_if { |t| t["id"] == req.args["id"].to_i }
  #         resp.render(List.new(todos: ::App.todos)) # Return a list view instead
  #       end
  #     end
  #
  #     def initialize(todo:)
  #       super()
  #       @todo = todo
  #     end
  #   end
  # end
  # ```
  class Component
    include RBX::Component

    attr_reader :request, :response

    def self.call(req, resp, **args)
      new(**args).call(req, resp)
    end

    def call(request, response)
      @request = request
      @response = response
      response.html(render)
    end
  end
end
