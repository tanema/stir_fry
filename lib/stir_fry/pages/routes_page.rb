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
    <StirFry.Pages.RouteList application={application}/>
  </section>
</StirFry.Pages.Layout>
