# frozen_string_literal: true

require "rack"
require "mustermann"

module Nextrb
  # App is the root of your Nextrb app that makes it runnable and ready for use
  # on any rack server
  class App
    DEFAULT_MIDDLEWARE = [
      [Rack::Head],
      [Rack::CommonLogger],
      [Rack::ShowStatus],
      [Rack::ShowExceptions],
      [Rack::ContentLength],
      [Rack::Reloader],
      [Rack::ContentType, "text/html"]
    ].freeze

    class << self
      def use(middleware_class, *args, &block) = middleware << [middleware_class, args, block]
      def get(pattern, options = nil, klass = nil, &) = route("GET", pattern, options, klass, &)
      def head(pattern, options = nil, klass = nil, &) = route("HEAD", pattern, options, klass, &)
      def options(pattern, options = nil, klass = nil, &) = route("OPTIONS", pattern, options, klass, &)
      def post(pattern, options = nil, klass = nil, &) = route("POST", pattern, options, klass, &)
      def put(pattern, options = nil, klass = nil, &) = route("PUT", pattern, options, klass, &)
      def patch(pattern, options = nil, klass = nil, &) = route("PATCH", pattern, options, klass, &)
      def delete(pattern, options = nil, klass = nil, &) = route("DELETE", pattern, options, klass, &)

      def static(dirname)
        dirname = File.expand_path(dirname)
        Dir[File.join(dirname, "**/*")].each do |path|
          path = File.expand_path(path)
          next unless File.file?(path)

          get path.to_s.delete_prefix(dirname) do |req, resp|
            resp.send_file(req, path)
          end
        end
      end

      # valid uses:
      # route("GET", "/") {}
      # route("GET", "/", Page)
      # route("GET", "/", {opt: true}) {}
      # route("GET", "/", {opt: true}, Page)
      def route(verb, pattern, args, klass, &block)
        options, klass = if args.is_a?(Class)
                           [{}, args]
                         else
                           [args || {}, klass]
                         end
        route_pat = Mustermann.new(pattern, **options.fetch(:path_options, {}))
        (routes[verb] ||= []) << [route_pat, options, klass || block]
      end

      def routes
        @routes ||= {}
      end

      def middleware
        @middleware ||= DEFAULT_MIDDLEWARE.dup
      end
    end

    # rubocop:disable Metrics/MethodLength
    def call(env)
      resp = Response.new(env)
      handle_request(Request.new(env), resp)
    rescue NotFound
      resp.not_found("Not found")
    rescue BadRequest
      resp.bad_request("Bad Request")
    rescue Unauthorized
      resp.unauthorized("Unauthorized")
    rescue Error => e
      resp.internal_error(e.message)
    rescue OKAY
      resp.finish
    ensure
      resp.finish
    end
    # rubocop:enable Metrics/MethodLength

    private

    def handle_request(req, resp)
      handler, _, req.args = find_route(req)
      verb = req.request_method.downcase.to_sym
      handler = handler.method(verb) if handler.respond_to?(verb)
      handler.call(req, resp)
      resp.finish
    end

    def find_route(req)
      self.class.routes[req.request_method]&.each do |route|
        params = route[0].params(req.path_info)
        return [route[2], route[1], params] if params
      end
      raise NotFound
    end
  end
end
