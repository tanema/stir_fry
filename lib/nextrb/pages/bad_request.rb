# frozen_string_literal: true

module Nextrb
  module Pages
    class BadRequest
      include RBX::Component

      attr_reader :req, :resp

      def self.call(req, resp)
        new(req, resp).call
      end

      def initialize(req, resp)
        @req = req
        @resp = resp
      end

      def call
        if req.json?
          resp.json({ error: "bad_request", message: message }, :bad_request)
        elsif req.html?
          resp.html(render, :bad_request)
        else
          resp.text(message, :bad_request)
        end
      end

      def message
        "Bad Request for #{req.request_method.upcase} #{req.path_info}"
      end
    end
  end
end

__END__
<Nextrb.Pages.Layout>
<section class="error-page">
  <p class="error-page__code">400</p>
  <h1 class="error-page__title">Bad Request</h1>
  <p class="error-page__message">{message}</p>
</section>
</Nextrb.Pages.Layout>
