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
  <head><link rel="stylesheet" href="/nextrb/nextrb.css" /></head>
  <body>{ yield }</body>
</html>
