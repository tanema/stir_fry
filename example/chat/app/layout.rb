# frozen_string_literal: true

# Layout is the default layout for the chat app.
class Layout < StirFry::Component; end

__END__
<!DOCTYPE html>
<html>
  <head>
    <title>Super Simple Chat with StirFry</title>
    <link rel="stylesheet" href="/chat.css" />
  </head>
  <body>{ yield }</body>
</html>
