require_relative "./layout"

module Todos
  autoload :Todo, File.expand_path("todos/todo", __dir__)
  autoload :Input, File.expand_path("todos/input", __dir__)
  autoload :List, File.expand_path("todos/list", __dir__)
end

class Root < Nextrb::Component
  def todos
    DB.all
  end
end

__END__
<Layout>
  <section class="todoapp">
    <header class="header">
      <h1>todos</h1>
      <Todos.Input />
		</header>
    <Todos.List todos={ todos }/>
  </section>
  <footer class="info">
    <p>Template by <a href="http://sindresorhus.com">Sindre Sorhus</a></p>
  </footer>
</Layout>
