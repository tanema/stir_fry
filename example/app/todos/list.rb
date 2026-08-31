# frozen_string_literal: true

module Todos
  # Input is the form to create new todos
  class Input < Nextrb::Component
  end

  # The component for listing todo items.
  class List < Nextrb::Component
    attr_reader :todos

    # POST /todo
    def self.post(request:, response:)
      new_todo = DB.create(request.params["text"])
      App.logger.info("Created new Todo #{new_todo[:id]} #{new_todo[:value]}")
      response.ok(new(todos: DB.all))
    end

    def initialize(todos:, **)
      super
      @todos = todos
    end
  end
end

__END__
@@ List
<section id="todo-list" class="main">
  <ul class="todo-list">
    {todos.map { |todo| <Todos.Todo todo={todo} /> }.join}
  </ul>
</section>

@@ Input
<form hx-post="/todo" hx-target="#todo-list" hx-swap="innerHTML" hx-on::after-request="if(event.detail.successful) this.reset()">
  <input class="new-todo" placeholder="Enter todo here..." name="text" type="text" required />
</form>
