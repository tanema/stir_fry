# frozen_string_literal: true

# Root is the root of the application, the home page.
class Root < StirFry::Component
  def todos = DB.all
end

__END__
<Layout>
  <section class="todoapp">
    <header class="header">
      <h1>todos</h1>
      <Input />
		</header>
    <List todos={ todos }/>
  </section>
</Layout>
