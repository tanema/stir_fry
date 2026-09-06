# frozen_string_literal: true

module TodosApp
  # Layout is the default layout for the todos app pages.
  class Layout < Nextrb::Component
    def htmx
      {
        src: "https://cdn.jsdelivr.net/npm/htmx.org@2.0.10/dist/htmx.min.js",
        integrity: "sha384-H5SrcfygHmAuTDZphMHqBJLc3FhssKjG7w/CeCpFReSfwBWDTKpkzPP8c+cLsK+V",
        crossorigin: "anonymous"
      }
    end
  end
end

__END__
<!DOCTYPE html>
<html>
  <head>
    <script {**htmx}></script>
    <link rel="stylesheet" href="/css/app.css" />
  </head>
  <body>
    { yield }
  </body>
</html>
