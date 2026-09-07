# frozen_string_literal: true

# The component for listing todo items.
class List < StirFry::Component
  attr_reader :todos

  # POST /todo
  def self.post(request:, response:, **)
    new_todo = DB.create(request.params["text"])
    logger.info("Created new Todo", id: new_todo[:id])
    response.ok(new(todos: DB.all))
  end

  def initialize(todos:, **)
    super
    @todos = todos
  end
end

__END__
<section id="todo-list" class="main">
  <ul class="todo-list">
    {todos.map { |todo| <Todo todo={todo} /> }.join}
  </ul>
</section>
