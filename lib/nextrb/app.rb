# frozen_string_literal: true

require "rack"
require "mustermann"

module Nextrb
  # App is the root of your Nextrb app that makes it runnable and ready for use
  # on any rack server
  class App
    DEFAULT_MIDDLEWARE = [
      [Rack::Head],
      [Rack::CommonLogger], # maybe not default and should be added by dev
      [Rack::ShowStatus], # disable in production
      [Rack::ShowExceptions], # disable in production
      [Rack::ContentLength]
    ].freeze

    DEFAULT_STATIC = [ # disable in production
      Rack::URLMap.new("/nextrb" => Rack::Files.new(File.join(__dir__, "static")))
    ].freeze

    DEFAULT_ERROR_HANDLERS = { # disable in production
      OKAY => ->(_req, resp, _err) { resp.finish },
      NotFound => ->(req, resp, err) { error_page(req, resp, :not_found, safe_err_message(err)) },
      BadRequest => ->(req, resp, err) { error_page(req, resp, :bad_request, safe_err_message(err)) },
      Unauthorized => ->(req, resp, err) { error_page(req, resp, :unauthorized, safe_err_message(err)) },
      InternalError => ->(req, resp, err) { error_page(req, resp, :internal_server_error, safe_err_message(err)) }
    }.freeze

    FALLBACK_ERROR_HANDLER = lambda { |req, resp, err|
      error_page(req, resp, :internal_server_error, safe_err_message(err))
    }.freeze

    REQUEST_ENV_KEY = "nextrb.request"
    RESPONSE_ENV_KEY = "nextrb.response"

    attr_accessor :request, :response, :env

    class << self
      def routes = @routes ||= {}
      def error_handlers = @error_handlers ||= DEFAULT_ERROR_HANDLERS.dup
      def use(middleware_class, *args, &block) = context.last[1] << [middleware_class, args, block]
      def get(pattern, options = nil, klass = nil, &) = route("GET", pattern, options, klass, &)
      def head(pattern, options = nil, klass = nil, &) = route("HEAD", pattern, options, klass, &)
      def options(pattern, options = nil, klass = nil, &) = route("OPTIONS", pattern, options, klass, &)
      def post(pattern, options = nil, klass = nil, &) = route("POST", pattern, options, klass, &)
      def put(pattern, options = nil, klass = nil, &) = route("PUT", pattern, options, klass, &)
      def patch(pattern, options = nil, klass = nil, &) = route("PATCH", pattern, options, klass, &)
      def delete(pattern, options = nil, klass = nil, &) = route("DELETE", pattern, options, klass, &)
      def rescue_from(klass, &block) = error_handlers[klass] = block

      def static(dirname, prefix: "/")
        files = Rack::Files.new(File.expand_path(dirname))
        static_apps << (prefix == "/" ? files : Rack::URLMap.new(prefix => files))
      end

      def scope(prefix = "")
        context.push([prefix, []])
        yield
      ensure
        context.pop
      end

      # valid uses:
      # route("GET", "/") {}
      # route("GET", "/", Page)
      # route("GET", "/", {opt: true}) {}
      # route("GET", "/", {opt: true}, Page)
      # route("GET", "/", {middleware: [AuthCheck]}, Page)
      def route(verb, pattern, args, klass, &block)
        options, klass = args.is_a?(Class) ? [{}, args] : [args || {}, klass]
        (routes[verb] ||= []) << [
          build_route(pattern, options),
          options,
          route_handler(klass || block, options.fetch(:middleware, []))
        ]
      end

      def call(env) = root_app.call(env)
      def _call = ->(env) { new(env).call }

      private

      def build_route(pattern, options) = Mustermann.new(route_prefix + pattern, **options.fetch(:path_options, {}))
      def static_apps = @static_apps ||= DEFAULT_STATIC.dup
      def context = @context ||= [["", DEFAULT_MIDDLEWARE.dup]]
      def root_app = @root_app ||= build_rack_app(context[0][1], Rack::Cascade.new(static_apps + [_call]))
      def normalize_middleware(list) = list.map { |m| m.is_a?(Array) ? [m[0], m[1..], nil] : [m, [], nil] }
      def route_prefix = context.map(&:first).join
      def route_middleware(mware) = context[1..].flat_map(&:last) + normalize_middleware(mware)
      def route_handler(handler, mware) = build_rack_app(route_middleware(mware), wrap_handler(handler))

      def safe_err_message(err) = err.message == err.class.name ? "" : err.message

      def error_page(req, resp, status, message = "")
        Pages::ErrorPage.call(req, resp, status, message)
        resp.finish
      end

      def wrap_handler(handler)
        lambda do |env|
          req = env.fetch(REQUEST_ENV_KEY)
          resp = env.fetch(RESPONSE_ENV_KEY)
          verb = req.request_method.downcase.to_sym
          handler = handler.method(verb) if handler.respond_to?(verb)
          handler.call(req, resp)
          resp.finish
        end
      end

      def build_rack_app(middleware, handler)
        builder = Rack::Builder.new
        middleware.each { |c, a, b| builder.use(c, *a, &b) }
        builder.run(handler)
        builder.to_app
      end
    end

    def initialize(env)
      @env = env
      @request = Request.new(env)
      @response = Response.new(env)
      env[REQUEST_ENV_KEY] = request
      env[RESPONSE_ENV_KEY] = response
    end

    def call
      find_route.call(env)
    rescue StandardError => e
      error_handler_for(e.class).call(env.fetch(REQUEST_ENV_KEY), env.fetch(RESPONSE_ENV_KEY), e)
    end

    private

    def error_handler_for(err_class)
      error_handlers = self.class.error_handlers
      err_class.ancestors.each { |klass| return error_handlers[klass] if error_handlers.key?(klass) }
      FALLBACK_ERROR_HANDLER
    end

    def find_route
      self.class.routes[request.request_method]&.each do |route|
        params = route[0].params(request.path_info)
        request.args = params if params
        return route[2] if params
      end
      raise NotFound
    end
  end
end
