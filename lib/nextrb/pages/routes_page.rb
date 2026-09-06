# frozen_string_literal: true

module Nextrb
  module Pages
    # Displays routes that are defined by the app. This is only enabled in development
    # and the route will not be define otherwise.
    class RoutesPage < Component; end
  end
end

__END__
<Nextrb.Pages.Layout>
  <section>
    <header><h1>Routes</h1></header>
    <section>
      <ul class="error-page__backtrace">
        {application.all_routes.map { |route| <li>{route}</li> }.join }
      </ul>
    </section>
  </section>
</Nextrb.Pages.Layout>
