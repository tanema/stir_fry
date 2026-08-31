# frozen_string_literal: true

require_relative "layout"

# Root is the root of the application, the home page.
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
