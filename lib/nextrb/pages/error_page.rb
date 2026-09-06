# frozen_string_literal: true

module Nextrb
  module Pages
    # ErrorPage is a custom component and main handler for server errors. It will
    # respond with a specific mime type depending on what was requested.
    class ErrorPage < Component
      # error is the error raised during the request cycle.
      attr_reader :error

      # Create a new error page that will display the message and status.
      def initialize(error: "", **args)
        super
        @error = error
      end

      # format a message from the error
      def message = error.message == error.class.name ? "" : error.message

      # status will derive a response status from the error raised.
      def status
        @status ||= case error
                    when NotFound then :not_found
                    when BadRequest then :bad_request
                    when Unauthorized then :unauthorized
                    when PreconditionFailed then :precondition_failed
                    else :internal_server_error
                    end
      end

      # Overrides Component#call to customize the output based on mime.
      def call
        if request.json? then response.json(render_json, status)
        elsif request.html? then response.html(render, status)
        else response.text(message, status)
        end
      end

      def title # :nodoc:
        Rack::Utils::HTTP_STATUS_CODES[response.status].to_s
      end

      private

      def render_json
        {
          error: title.downcase.tr(" ", "_"),
          message: message
        }
      end
    end
  end
end

__END__
<Nextrb.Pages.Layout>
  <section>
    <header><h1>{title}</h1></header>
    <section class="error-page">
      <p class="error-page__code">{response.status}</p>
      <p class="error-page__path">{ "[#{request.request_method.upcase}] #{request.host_with_port}#{request.path_info}" }</p>
      <p class="error-page__message">{message}</p>
      <ul class="error-page__backtrace">
        {error.backtrace.map {|t| <li>{t.to_s}</li> }.join }
      </ul>
    </section>
  </section>
</Nextrb.Pages.Layout>
