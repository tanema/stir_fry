# frozen_string_literal: true

module Nextrb
  module Pages
    class Layout < Component
      STYLE = <<~CSS
        :root {
          --ruby-red: #cc342d;
          --ruby-green: #2e8b57;
          --ink: #2b2b2b;
          --muted: #6b6b6b;
        }

        * { box-sizing: border-box; }

        body {
          margin: 0;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
          color: var(--ink);
          background: #fafafa;
        }

        section {
          max-width: 640px;
          margin: 0 auto;
          padding: 2rem 1.5rem;
        }

        header h1 {
          display: inline-block;
          color: var(--ruby-red);
          border-bottom: 3px solid var(--ruby-green);
          padding-bottom: 0.5rem;
        }

        footer.info {
          color: var(--muted);
          font-size: 0.875rem;
          border-top: 1px solid #e0e0e0;
          padding-top: 1rem;
        }

        footer.info a {
          color: var(--ruby-green);
          text-decoration: none;
        }

        footer.info a:hover {
          text-decoration: underline;
        }

        .error-page {
          text-align: center;
          padding: 4rem 1.5rem;
        }

        .error-page__code {
          margin: 0;
          color: var(--ruby-red);
          font-size: 4rem;
          font-weight: 700;
        }

        .error-page__title {
          margin: 0.5rem 0 1rem;
        }

        .error-page__message {
          color: var(--muted);
        }
      CSS
    end
  end
end

__END__
<!DOCTYPE html>
<html>
  <head>
    <style>{ RBX.safe(STYLE) }</style>
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
