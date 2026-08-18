module Todos
  class List < Nextrb::Component::Base
    attr_reader :todos

    # POST /todo
    def self.post(req, resp)
      ::App.todos << { "id" => ::App.next_id, "text" => req.params["text"] }
      ::App.next_id += 1
      resp.render(self, todos: ::App.todos)
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
    {todos.map { |todo| <Todos.Todo todo={todo} /> } }
  </ul>
</section>
