# frozen_string_literal: true

module ChatApp
  # Layout is the default layout for the chat app.
  class Layout < Nextrb::Component; end
end

__END__
<!DOCTYPE html>
<html>
  <head><title>Super Simple Chat with Nextrb</title></head>
  <body>{ yield }</body>
</html>
