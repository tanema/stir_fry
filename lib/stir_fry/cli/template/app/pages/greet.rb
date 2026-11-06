# frozen_string_literal: true

module Pages
  # /:name endpoint to say hello to you
  class Greet < StirFry::Component
    # The name passed in through the route param.
    attr_reader :name

    def initialize(name:, **) # :nodoc:
      super
      logger.info("Greeting #{name}")
      @name = name
    end
  end
end

__END__
<Pages.Layout>
  <h1>Hello {name}!</h1>
</Pages.Layout>
