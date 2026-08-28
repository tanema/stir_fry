module Todos
  class List < Nextrb::Component
    attr_reader :todos

    # POST /todo
    def self.post(req, resp)
      DB.create(req.params["text"])
      resp.ok(new(todos: DB.all))
    end

    def initialize(todos:)
      super()
      @todos = todos
    end
  end
end

__END__
<section id="todo-list" class="main">
  <ul class="todo-list">
    {todos.map { |todo| <Todos.Todo todo={todo} /> }.join}
  </ul>
</section>
