# frozen_string_literal: true

module StirFry
  module Pages
    # Displays routes that are defined by the app. This is only enabled in development
    # and the route will not be define otherwise.
    class RoutesPage < Component; end
  end
end

__END__
<StirFry.Pages.Layout>
  <section>
    <header><h1>Routes</h1></header>
    <nav class="route-list">
      <p class="route-list__caption">{ "#{application.route_table.length} registered routes" }</p>
      <ul class="route-list__items">
        {application.route_table.map { |verb, path| <li class="route-list__item"><span class="route-list__verb" data-verb={verb}>{verb}</span><code class="route-list__path">{path}</code></li> }.join }
      </ul>
    </nav>
  </section>
</StirFry.Pages.Layout>
