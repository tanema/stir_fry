# frozen_string_literal: true

require "json"

module Nextrb
  module Middleware
    # Logger is our custom logger for a better format using a shared logger
    class Logger
      # Create the new middleware for logging
      def initialize(app, logger = ::Logger.new($stdout))
        @app = app
        @logger = logger
      end

      # Middleware call that logs the request and it's response.
      def call(env)
        began_at = Time.now.to_f
        content = @app.call(env)
        log(env, Time.now.to_f - began_at)
        content
      end

      private

      def log(env, elapsed)
        req = env.fetch(App::REQUEST_ENV_KEY, Rack::Request.new(env))
        resp = env.fetch(App::RESPONSE_ENV_KEY, Rack::Response.new(env))
        log_method(resp).call(log_line(req, resp, elapsed))
      end

      def log_method(resp)
        if resp.status.between?(100, 299)
          @logger.method(:info)
        elsif resp.status.between?(300, 499)
          @logger.method(:warn)
        else
          @logger.method(:error)
        end
      end

      def log_line(req, resp, elapsed)
        {
          method: req.request_method,
          path: req.path_info,
          query: req.query_string,
          status: resp.status,
          user: client_log(req),
          request: req_log(req),
          response: resp_log(resp, elapsed)
        }.compact
      end

      def client_log(req)
        {
          ip: req.ip,
          remote_user: req.get_header("REMOTE_USER")
        }.compact
      end

      def req_log(req)
        {
          accept_encoding: req.get_header("HTTP_ACCEPT"),
          scheme: req.scheme,
          server_authority: req.server_authority,
          referer: req.referer,
          script_name: req.script_name,
          media_type: req.media_type,
          proto: req.get_header("SERVER_PROTOCOL")
        }.compact
      end

      def resp_log(resp, elapsed)
        line = {
          content_type: resp.headers["Content-Type"],
          content_length: resp.headers["Content-Length"],
          elapsed: elapsed % 60
        }

        if resp.respond_to?(:request_error)
          line[:error] = resp.request_error&.message&.to_s
          line[:error_stacktrace] = resp.request_error&.backtrace
        end

        line.compact
      end
    end
  end
end
