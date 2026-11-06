# frozen_string_literal: true

module StirFry
  module Pages
    # Layout is the layout of the frameworks pages that it serves.
    class Layout < Component; end
  end
end

__END__
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="/stir_fry/stir_fry.css" />
  </head>
  <body>{ yield }</body>
</html>
