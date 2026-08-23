# frozen_string_literal: true

module Nextrb
  module Pages
    class InternalError
      include RBX::Component

      attr_reader :req, :resp, :message

      def self.call(req, resp, message)
        new(req, resp, message).call
      end

      def initialize(req, resp, message)
        @req = req
        @resp = resp
        @message = message
      end

      def call
        if req.json?
          resp.json({ error: "internal_error", message: message }, 500)
        elsif req.html?
          resp.html(render, 500)
        else
          resp.text(message, 500)
        end
      end
    end
  end
end

__END__
<Nextrb.Pages.Layout>
<section class="error-page">
  <p class="error-page__code">500</p>
  <h1 class="error-page__title">Internal Error</h1>
  <p class="error-page__message">{message}</p>
</section>
</Nextrb.Pages.Layout>
