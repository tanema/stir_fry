# frozen_string_literal: true

module StirFry
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
  #   class Todo < StirFry::Component
  #     attr_reader :todo
  #
  #     class << self
  #       # PUT /todo/:id/toggle
  #       def put(request:, response:, id:)
  #         todo = ::App.todos.find { |t| t["id"] == id.to_i }
  #         todo["done"] = !todo["done"]
  #         response.ok(new(todo: todo)) # Return a Todo view
  #       end
  #
  #       # DELETE /todo/:id
  #       def delete(request:, response:, id:)
  #         ::App.todos.delete_if { |t| t["id"] == id.to_i }
  #         response.render(List.new(todos: ::App.todos)) # Return a list view instead
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

    # application is root application where all the routes are defined and maybe
    # where you might keep config or database references.
    # This is only defined on the root component that is defined on the route.
    attr_accessor :application
    # request is the request that called this component. This is only defined on the root
    # component that is defined on the route.
    attr_accessor :request
    # response is the response that is used for responding in the component.
    # This is only defined on the root component that is defined on the route.
    attr_accessor :response

    # Simple access to StirFry.logger
    def self.logger = StirFry.logger

    # call it the method called from routing. It is called with the request and response
    # first, and the arguments to initialize the component will be appended to the
    # end. It will set the request, and response on the component and call render
    # on the component.
    def self.call(application: nil, request: nil, response: nil, **args)
      new(application: application, request: request, response: response, **args).call
    end

    # create a new component with a request and response
    def initialize(application: nil, request: nil, response: nil, **_args)
      self.application = application
      self.request = request
      self.response = response
    end

    # call is sugar for `response.html(render)` and should be overriden to change how
    # a component responds.
    def call
      response.html(render)
    end

    # Simple access to StirFry.logger
    def logger = StirFry.logger
  end
end
