# frozen_string_literal: true

require "rack"
require "mustermann"

module Nextrb
  # App is the root of your Nextrb app that makes it runnable and ready for use
  # on any rack server
  #
  # Example:
  #
  # ```ruby
  # class App < Nextrb::App
  #   get "/" do |req, resp|
  #     resp.text("Hello world")
  #   end
  #   get "/todo", Todos::List
  # end
  #
  # Nextrb.run!(App)
  # ```
  class App
    DEFAULT_MIDDLEWARE = [ # :nodoc:
      [Rack::Head],
      [Rack::CommonLogger], # maybe not default and should be added by dev
      [Rack::ShowStatus], # disable in production
      [Rack::ShowExceptions], # disable in production
      [Rack::ContentLength]
    ].freeze

    DEFAULT_STATIC = [ # :nodoc: disable in production
      Rack::URLMap.new("/nextrb" => Rack::Files.new(File.join(__dir__, "static")))
    ].freeze

    DEFAULT_ERROR_HANDLERS = { # :nodoc: disable in production
      OKAY => ->(_req, resp, _err) { resp.finish },
      NotFound => ->(req, resp, err) { error_page(req, resp, :not_found, safe_err_message(err)) },
      BadRequest => ->(req, resp, err) { error_page(req, resp, :bad_request, safe_err_message(err)) },
      Unauthorized => ->(req, resp, err) { error_page(req, resp, :unauthorized, safe_err_message(err)) },
      InternalError => ->(req, resp, err) { error_page(req, resp, :internal_server_error, safe_err_message(err)) }
    }.freeze

    FALLBACK_ERROR_HANDLER = lambda { |req, resp, err| # :nodoc:
      error_page(req, resp, :internal_server_error, safe_err_message(err))
    }.freeze

    REQUEST_ENV_KEY = "nextrb.request" # :nodoc:
    RESPONSE_ENV_KEY = "nextrb.response" # :nodoc:

    attr_accessor :request, :response, :env # :nodoc:

    class << self
      def routes = @routes ||= {} # :nodoc:
      def error_handlers = @error_handlers ||= DEFAULT_ERROR_HANDLERS.dup # :nodoc:
      def call(env) = root_app.call(env) # :nodoc:

      # Add a GET request route to the application
      def get(pattern, klass = nil, &) = route("GET", pattern, klass, &)

      # Add a HEAD request route to the application
      def head(pattern, klass = nil, &) = route("HEAD", pattern, klass, &)

      # Add a OPTIONS request route to the application
      def options(pattern, klass = nil, &) = route("OPTIONS", pattern, klass, &)

      # Add a POST request route to the application
      def post(pattern, klass = nil, &) = route("POST", pattern, klass, &)

      # Add a PUT request route to the application
      def put(pattern, klass = nil, &) = route("PUT", pattern, klass, &)

      # Add a PATCH request route to the application
      def patch(pattern, klass = nil, &) = route("PATCH", pattern, klass, &)

      # Add a DELETE request route to the application
      def delete(pattern, klass = nil, &) = route("DELETE", pattern, klass, &)

      ##
      # Add a handler for an error raised during runtime.
      #
      # Example:
      #
      # ```ruby
      # class App < Nextrb::App
      #   rescue_from Nextrb::NotFound do |req, resp|
      #     resp.text("Not Found", :not_found)
      #   end
      # end
      # ```
      def rescue_from(klass, &block) = error_handlers[klass] = block

      ##
      # Adds a middleware class to the chain of middleware. The order of operations
      # is significant! So if you create routes before you add a middleware, the
      # routes will not include the later middleware. This can be nice to scope
      # your middleware but it can also be an easy mistake.
      def use(middleware_class, *args, &block) = context.last[1] << [middleware_class, args, block]

      ##
      # Hosts a directory of static files. Every file within the directory will
      # be requestable and sym links are followed so be careful what you host.
      # A prefix can be added to the file routes to allow them to be scoped to a
      # certain endpoint.
      #
      # Example:
      #
      # ```ruby
      # class App < Nextrb::App
      #   static File.join(__dir__, "public")
      # end
      # ```
      def static(dirname, prefix: "/")
        files = Rack::Files.new(File.expand_path(dirname))
        static_apps << (prefix == "/" ? files : Rack::URLMap.new(prefix => files))
      end

      ##
      # Creates a sub-scope of routes that allow to prefix all the routes and add
      # specific middleware that only applies to those routes.
      #
      # Example:
      #
      # ```ruby
      # class App < Nextrb::App
      #   scope "/todos" do
      #     use AuthenticationMiddleware
      #
      #     get "/:id", Todo
      #     delete "/:id", Todo
      #     post "/:id", Todo
      #   end
      # end
      # ```
      def scope(prefix = "", &)
        context.push([prefix, []])
        yield
      ensure
        context.pop
      end

      ##
      # Raw route builder, used by the other helper models so `get("/")` becomes
      # `route("GET", "/")`
      def route(verb, pattern, klass, &block)
        (routes[verb] ||= []) << [Mustermann.new(route_prefix + pattern), route_handler(klass || block)]
      end

      private

      def static_apps = @static_apps ||= DEFAULT_STATIC.dup
      def context = @context ||= [["", DEFAULT_MIDDLEWARE.dup]]
      def route_prefix = context.map(&:first).join
      def route_handler(handler) = build_rack_app(context[1..].flat_map(&:last), wrap_handler(handler))
      def safe_err_message(err) = err.message == err.class.name ? "" : err.message

      def root_app
        @root_app ||= build_rack_app(context[0][1], Rack::Cascade.new(static_apps + [->(env) { new(env).call }]))
      end

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

    def initialize(env) # :nodoc:
      @env = env
      @request = Request.new(env)
      @response = Response.new(env)
      env[REQUEST_ENV_KEY] = request
      env[RESPONSE_ENV_KEY] = response
    end

    def call # :nodoc:
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
        return route[1] if params
      end
      raise NotFound
    end
  end
end
