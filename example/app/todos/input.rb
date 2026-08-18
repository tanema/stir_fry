module Todos
  class Input < Nextrb::Component::Base
  end
end

__END__
<form hx-post="/todo" hx-target="#todo-list" hx-swap="innerHTML" hx-on::after-request="if(event.detail.successful) this.reset()">
  <input class="new-todo" placeholder="Enter todo here..." name="text" type="text" required />
</form>
