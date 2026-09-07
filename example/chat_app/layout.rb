# frozen_string_literal: true

module ChatApp
  # Layout is the default layout for the chat app.
  class Layout < StirFry::Component; end
end

__END__
<!DOCTYPE html>
<html>
  <head>
    <title>Super Simple Chat with StirFry</title>
    <link rel="stylesheet" href="/chat.css" />
  </head>
  <body>{ yield }</body>
</html>
