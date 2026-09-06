# frozen_string_literal: true

module TodosApp
  # Input is the form to create new todos
  class Input < Nextrb::Component; end
end

__END__
<form hx-post="/todo" 
      hx-target="#todo-list" 
      hx-swap="innerHTML" 
      hx-on::after-request="if(event.detail.successful) this.reset()">
  <input class="new-todo" 
         placeholder="Enter todo here..." 
         name="text" 
         type="text" 
         required />
</form>
