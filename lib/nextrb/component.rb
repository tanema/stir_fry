# frozen_string_literal: true

module Nextrb
  # Component is a single view handler
  class Component
    def template
      _, data = File.read(__FILE__).split(/^__END__$/, 2)
      data
    end

    def call
      # Rbexy.evaluate(template, self)
    end
  end
end
