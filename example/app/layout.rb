# frozen_string_literal: true

class Layout < Nextrb::Component
end

__END__
<!DOCTYPE html>
<html>
  <head>
    <script src="https://cdn.jsdelivr.net/npm/htmx.org@2.0.10/dist/htmx.min.js" 
            integrity="sha384-H5SrcfygHmAuTDZphMHqBJLc3FhssKjG7w/CeCpFReSfwBWDTKpkzPP8c+cLsK+V"
            crossorigin="anonymous"></script>
    <link rel="stylesheet" href="/css/app.css" />
  </head>
  <body>
    { yield }
  </body>
</html>
