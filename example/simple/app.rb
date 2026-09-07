# frozen_string_literal: true

require "stir_fry"

# rubocop:disable Style/OneClassPerFile

class Layout < StirFry::Component; end # :nodoc:
class Home < StirFry::Component; end # :nodoc:

class Greet < StirFry::Component # :nodoc:
  attr_reader :name

  def initialize(name:, **)
    super
    logger.info("Greeting #{name}")
    @name = name
  end
end

class App < StirFry::App # :nodoc:
  get "/", Home
  get "/:name", Greet
  get "/api/:name" do |name:, response:, **|
    response.json({ message: "Hello #{name}!" })
  end
end

# rubocop:enable Style/OneClassPerFile

__END__
@@Layout
<html>
  <body>
    { yield }
  </body>
</html>

@@Home
<Layout>
  <h1>Hello World</h1>
</Layout>

@@Greet
<Layout>
  <h1>Hello {name}!</h1>
</Layout>

