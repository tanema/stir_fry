# frozen_string_literal: true

module Nextrb
  module Pages
    # ErrorPage is a main handler for server errors
    class ErrorPage
      include RBX::Component

      attr_reader :req, :resp, :message

      def self.call(req, resp, status, message = "")
        resp.status(status)
        new(req, resp, message).call
      end

      def initialize(req, resp, message)
        @req = req
        @resp = resp
        @message = message
      end

      def call
        if req.json?
          resp.json({ error: error_code, message: message }, resp.status)
        elsif req.html?
          resp.html(render, resp.status)
        else
          resp.text(message, resp.status)
        end
      end

      def title
        Rack::Utils::HTTP_STATUS_CODES[resp.status].to_s
      end

      def error_code
        title.downcase.tr(" ", "_")
      end
    end
  end
end

__END__
<Nextrb.Pages.Layout>
<section class="error-page">
  <p class="error-page__code">{resp.status}</p>
  <h1 class="error-page__title">{title}</h1>
  <p class="error-page__path">{ "[#{req.request_method.upcase}] #{req.host_with_port}#{req.path_info}" }</p>
  <p class="error-page__message">{message}</p>
</section>
</Nextrb.Pages.Layout>
