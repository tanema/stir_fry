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

    @context = [["", DEFAULT_MIDDLEWARE.dup]]
    @routes = {}

    attr_accessor :request, :response, :env

    class << self
      attr_accessor :context, :routes

      def use(middleware_class, *args, &block) = context.last[1] << [middleware_class, args, block]
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

      def scope(prefix = "")
        context.push([prefix, []])
        yield
        context.pop
      end

      def route(verb, pattern, args, klass, &block)
        options, klass = if args.is_a?(Class)
                           [{}, args]
                         else
                           [args || {}, klass]
                         end
        prefix = context.each_with_object("") { |ctx, pfx| pfx + ctx[0] }
        # middleware = options.fetch(:middleware, {})
        route_pat = Mustermann.new(prefix + pattern, **options.fetch(:path_options, {}))
        (routes[verb] ||= []) << [route_pat, options, klass || block]
      end

      def call(env)
        new(env).call
      end
    end

    def initialize(env)
      @env = env
      @request = Request.new(env)
      @response = Response.new(env)
    end

    def call
      handle_request
    rescue NotFound
      error_page(:not_found)
    rescue BadRequest
      error_page(:bad_request)
    rescue Unauthorized
      error_page(:unauthorized)
    rescue Error => e
      error_page(:internal_server_error, e.message)
    end

    private

    def error_page(status, message = "")
      Pages::ErrorPage.call(request, response, status, message)
      response.finish
    end

    def handle_request
      handler, _, request.args = find_route
      verb = request.request_method.downcase.to_sym
      handler = handler.method(verb) if handler.respond_to?(verb)
      handler.call(request, response)
      response.finish
    end

    def find_route
      self.class.routes[request.request_method]&.each do |route|
        params = route[0].params(request.path_info)
        return [route[2], route[1], params] if params
      end
      raise NotFound
    end
  end
end
