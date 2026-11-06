# frozen_string_literal: true

# Input is the form to create new todos
class Input < StirFry::Component
  def input_attrs
    {
      class: "new-todo",
      placeholder: "Enter todo here...",
      name: "text",
      type: "text",
      required: true
    }
  end

  def form_attrs
    {
      hx: {
        post: "/todo",
        target: "#todo-list",
        swap: "innerHTML",
        "on::after-request": "if(event.detail.successful) this.reset()"
      }
    }
  end
end

__END__
<form {**form_attrs}>
  <input {**input_attrs} />
</form>
