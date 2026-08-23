# frozen_string_literal: true

module Nextrb
  module Pages
    class Unauthorized
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
          resp.json({ error: "unauthorized", message: message }, :unauthorized)
        elsif req.html?
          resp.html(render, :unauthorized)
        else
          resp.text(message, :unauthorized)
        end
      end

      def message
        "Unauthorized to make request to #{req.request_method.upcase} #{req.path_info}"
      end
    end
  end
end

__END__
<Nextrb.Pages.Layout>
<section class="error-page">
  <p class="error-page__code">401</p>
  <h1 class="error-page__title">Unauthorized</h1>
  <p class="error-page__message">{message}</p>
</section>
</Nextrb.Pages.Layout>
