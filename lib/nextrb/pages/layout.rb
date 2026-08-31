# frozen_string_literal: true

module Nextrb
  module Pages
    # Layout is the layout of the frameworks pages that it serves.
    class Layout < Component; end
  end
end

__END__
<!DOCTYPE html>
<html>
  <head>
    <link rel="stylesheet" href="/nextrb/error_page.css" />
  </head>
  <body>
    <section>
      <header><h1>Nextrb</h1></header>
      { yield }
      <footer class="info">
        <p>If there is an issue with the framework please <a href="https://github.com/tanema/nextrb/issues">open an issue.</a></p>
      </footer>
    </section>
  </body>
</html>
