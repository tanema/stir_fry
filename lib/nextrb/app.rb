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
  #   get "/greet/:name" do |request:, response:, name:|
  #     response.text("Hello #{name}")
  #   end
  #   get "/todo", Todos::List
  # end
  #
  # Nextrb.run!(App)
  # ```
  class App
    DEFAULT_DEVELOPMENT_MIDDLEWARE = [ # :nodoc:
      [Rack::Head],
      [Rack::ShowStatus],
      [Rack::ShowExceptions],
      [Rack::ContentLength]
    ].freeze

    DEFAULT_PRODUCTION_MIDDLEWARE = [ # :nodoc:
      [Rack::Head],
      [Rack::ContentLength]
    ].freeze

    DEFAULT_STATIC = [ # :nodoc:
      Rack::URLMap.new("/nextrb" => Rack::Files.new(File.join(__dir__, "static")))
    ].freeze

    DEFAULT_ERROR_HANDLERS = { # :nodoc: disable in production
      OKAY => ->(**args) { pass_through(status: :ok, **args) },
      Found => ->(**args) { pass_through(status: :found, **args) },
      NotModified => ->(**args) { pass_through(status: :not_modified, **args) },
      NotFound => Pages::ErrorPage,
      BadRequest => Pages::ErrorPage,
      Unauthorized => Pages::ErrorPage,
      InternalError => Pages::ErrorPage,
      PreconditionFailed => Pages::ErrorPage
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

      # running environment for this app.
      def app_env = Nextrb.app_env

      # is the app running in development.
      def development? = app_env == :development

      # is the app running in test.
      def test? = app_env == :test

      # is the app running in production
      def production? = app_end == :production

      # configured logger for the application for easy access in the app
      def logger = Nextrb.logger

      def pass_through(response:, status:, **) # :nodoc:
        response.status(status)
      end

      ##
      # Add a handler for an error raised during runtime.
      #
      # Example:
      #
      # ```ruby
      # class App < Nextrb::App
      #   rescue_from Nextrb::NotFound do |request:, response:, error:|
      #     response.text("Not Found", :not_found)
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

      def static_apps = @static_apps ||= (development? ? DEFAULT_STATIC.dup : [])

      def context
        @context ||= [["", development? ? DEFAULT_DEVELOPMENT_MIDDLEWARE.dup : DEFAULT_PRODUCTION_MIDDLEWARE]]
      end

      def route_prefix = context.map(&:first).join
      def route_handler(handler) = build_rack_app(context[1..].flat_map(&:last), wrap_handler(handler))

      def root_app
        @root_app ||= begin
          builder = Rack::Builder.new
          context[0][1].each { |c, a, b| builder.use(c, *a, &b) }
          builder.use(Middleware::Logger, logger)
          builder.run(Rack::Cascade.new(static_apps + [->(env) { new(env).call }]))
          builder.to_app
        end
      end

      def wrap_handler(handler)
        lambda do |env|
          req = env.fetch(REQUEST_ENV_KEY)
          resp = env.fetch(RESPONSE_ENV_KEY)
          verb = req.request_method.downcase.to_sym
          handler = handler.method(verb) if handler.respond_to?(verb)
          call_params = req.args.to_h { |k, v| [k.to_sym, v] }.merge({ request: req, response: resp })
          handler.call(**call_params)
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

    # running environment for this app.
    def app_env = self.class.app_env
    # is the app running in development.
    def development? = self.class.development?
    # is the app running in test.
    def test? = self.class.test?
    # is the app running in production
    def production? = self.class.production?
    # configured logger for the application for easy access in the app
    def logger = self.class.logger

    def call # :nodoc:
      find_route.call(env)
    rescue StandardError => e
      handle_error(e)
    end

    private

    def handle_error(err)
      handler = error_handler_for(err.class)
      handler.call(request: request, response: response, error: err)
      response.finish
    end

    def error_handler_for(err_class)
      error_handlers = self.class.error_handlers
      err_class.ancestors.each { |klass| return error_handlers[klass] if error_handlers.key?(klass) }
      Pages::ErrorPage
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
