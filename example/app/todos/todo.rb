module Todos
  class Todo < Nextrb::Component::Base
    attr_reader :todo

    class << self
      # PUT /todo/:id/toggle
      def put(req, resp)
        todo = ::App.todos.find { |t| t["id"] == req.args["id"].to_i }
        todo["done"] = !todo["done"]
        resp.render(self, todo: todo)
      end

      # DELETE /todo/:id
      def delete(req, resp)
        ::App.todos.delete_if { |t| t["id"] == req.args["id"].to_i }
        resp.render(List, todos: ::App.todos)
      end
    end

    def initialize(todo:)
      super()
      @todo = todo
    end

    def list_key
      "todo-#{todo["id"]}"
    end

    def checkbox_attrs
      {
        class: "toggle",
        name: "done",
        checked: todo["done"] == true,
        hx: {
          put: "/todo/#{todo["id"]}/toggle",
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
    <label>{ todo["text"] }</label>
    <button class="destroy" hx-delete={ "/todo/#{todo["id"]}" } hx-target="#todo-list" hx-swap="innerHTML"></button>
  </div>
</li>
