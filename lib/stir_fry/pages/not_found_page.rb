# frozen_string_literal: true

module StirFry
  module Pages
    # NotFoundPage is a simple page to display 404 errors appropriate for the
    # request mime type
    class NotFoundPage < Component
      # Overrides Component#call to customize the output based on mime.
      def call
        if request.json? then response.json({ error: "not_found", message: "Not Found" }, :not_found)
        elsif request.html? then response.html(render, :not_found)
        else response.text("Not Found", :not_found)
        end
      end
    end
  end
end

__END__
<StirFry.Pages.Layout>
  <section>
    <header><h1>Not Found</h1></header>
    <section class="error-page">
      <p class="error-page__code">404</p>
      <p class="error-page__message">Request path did not match any registered routes.</p>
    </section>
    <StirFry.Pages.RouteList application={application}/>
  </section>
</StirFry.Pages.Layout>
