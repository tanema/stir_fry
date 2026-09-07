# frozen_string_literal: true

module TodosApp
  # a single todo element to display in the list. It also handles toggling and
  # deleteing todos
  class Todo < StirFry::Component
    attr_reader :todo

    class << self
      # PUT /todo/:id/toggle
      def put(response:, id:, **)
        todo_id = id.to_i
        todo = DB.update(todo_id, done: !DB.find(todo_id)[:done])
        logger.info("toggle Todo", done: todo[:done])
        response.ok(new(todo: todo))
      end

      # DELETE /todo/:id
      def delete(response:, id:, **)
        DB.delete(id.to_i)
        logger.info("Deleted Todo", id: id)
        response.render(List.new(todos: DB.all))
      end
    end

    def initialize(todo:, **)
      super
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
        hx: checkbox_hx_attrs
      }
    end

    def checkbox_hx_attrs
      {
        put: "/todo/#{todo[:id]}/toggle",
        trigger: "change",
        target: "##{list_key}",
        swap: "outerHTML"
      }
    end

    def delete_attrs
      {
        class: "destroy",
        hx: {
          delete: "/todo/#{todo[:id]}",
          target: "#todo-list",
          swap: "innerHTML"
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
    <button {**delete_attrs}></button>
  </div>
</li>
