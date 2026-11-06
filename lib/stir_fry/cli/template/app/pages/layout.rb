# frozen_string_literal: true

module Pages
  # layout for all pages
  class Layout < StirFry::Component
  end
end

__END__
<html>
  <body>
    { yield }
  </body>
</html>
