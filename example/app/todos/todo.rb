module Todos
  class Todo < Nextrb::Component
    attr_reader :todo

    class << self
      # PUT /todo/:id/toggle
      def put(req, resp)
        todo_id = req.args["id"].to_i
        todo = DB.update(todo_id, done: !DB.find(todo_id)[:done])
        resp.ok(new(todo: todo))
      end

      # DELETE /todo/:id
      def delete(req, resp)
        DB.delete(req.args["id"].to_i)
        resp.render(List.new(todos: DB.all))
      end
    end

    def initialize(todo:)
      super()
      @todo = todo
    end

    def list_key
      "todo-#{todo[:id]}"
    end

    def checkbox_attrs
      {
        class: "toggle",
        name: "done",
        checked: todo[:done] == true,
        hx: {
          put: "/todo/#{todo[:id]}/toggle",
          trigger: "change",
          target: "##{list_key}",
          swap: "outerHTML"
        }
      }
    end
  end
end

__END__
<li id={list_key}>
  <div class="view">
    <input type="checkbox" {**checkbox_attrs} />
    <label>{ todo[:value] }</label>
    <button class="destroy"
            hx-delete={ "/todo/#{todo[:id]}" }
            hx-target="#todo-list" 
            hx-swap="innerHTML"></button>
  </div>
</li>
