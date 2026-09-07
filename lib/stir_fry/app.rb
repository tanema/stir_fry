# frozen_string_literal: true

require "rack"
require "rack/session"
require "mustermann"

module StirFry
  # App is the root of your StirFry app that makes it runnable and ready for use
  # on any rack server
  #
  # Example:
  #
  # ```ruby
  # class App < StirFry::App
  #   get "/greet/:name" do |response:, **|
  #     response.text("Hello #{name}")
  #   end
  #   get "/todo", Todos::List
  # end
  #
  # StirFry.run!(App)
  # ```
  class App
    DEFAULT_ERROR_HANDLERS = { # :nodoc: disable in production
      OKAY => ->(**args) { pass_through(status: :ok, **args) },
      Found => ->(**args) { pass_through(status: :found, **args) },
      NotModified => ->(**args) { pass_through(status: :not_modified, **args) },
      NotFound => Pages::NotFoundPage
    }.freeze

    REQUEST_ENV_KEY = "stir_fry.request" # :nodoc:
    RESPONSE_ENV_KEY = "stir_fry.response" # :nodoc:

    attr_accessor :request, :response, :env # :nodoc:

    class << self
      def routes = @routes ||= {} # :nodoc:
      def all_routes = @all_routes ||= [] # :nodoc:
      def error_handlers = @error_handlers ||= DEFAULT_ERROR_HANDLERS.dup # :nodoc:
      def call(env) = root_app.call(env) # :nodoc:

      # sugar for `use Rack::Session::Cookie, config`
      # See https://github.com/rack/rack-session for more config.
      # Params:
      # - `domain`       host for the cookie security (example: 'mywebsite.com')
      # - `path`         path for the cookie security (example: '/')
      # - `expire_after` mark the cookie as expired after seconds (example: 3600*24)
      # - `max_age`      similar to expires_after.
      # - `secret`       *required* a random string 64 character long or longer. Used to encrypt cookie.
      def use_session(**config)
        raise "cannot enable sessions without a :secret set." if config[:secret].nil?

        secret_len = config[:secret].length
        if secret_len < 64
          raise "session secret too short, secret is #{secret_len} but session secret is required to be >= 64"
        end

        use Rack::Session::Cookie, config
      end

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
      def app_env = StirFry.app_env

      # is the app running in development.
      def development? = app_env == :development

      # is the app running in test.
      def test? = app_env == :test

      # is the app running in production
      def production? = app_end == :production

      # configured logger for the application for easy access in the app
      def logger = StirFry.logger

      def pass_through(response:, status:, **) # :nodoc:
        response.status(status)
      end

      ##
      # Add a handler for an error raised during runtime.
      #
      # Example:
      #
      # ```ruby
      # class App < StirFry::App
      #   rescue_from StirFry::NotFound do |response:, **|
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
      # class App < StirFry::App
      #   static File.join(__dir__, "public")
      # end
      # ```
      def static(dirname, path: "/")
        files = Rack::Files.new(File.expand_path(dirname))
        path = route_prefix + path
        static_apps << (path == "/" ? files : Rack::URLMap.new(path => files))
      end

      ##
      # Creates a sub-scope of routes that allow to prefix all the routes and add
      # specific middleware that only applies to those routes.
      #
      # Example:
      #
      # ```ruby
      # class App < StirFry::App
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
        path_pattern = Mustermann.new(route_prefix + pattern)
        all_routes << path_pattern.to_s unless path_pattern.to_s.start_with?("/stir_fry")
        (routes[verb] ||= []) << [path_pattern, route_handler(klass || block)]
      end

      protected

      def setup_default_middleware # :nodoc:
        use Middleware::Logger, logger
        use Rack::Head
        use Rack::ShowStatus if development?
        use Rack::ShowExceptions if development?
        use Rack::ContentLength
      end

      def setup_framework_routes # :nodoc:
        scope "/stir_fry" do
          static File.join(__dir__, "static")
          get "/routes", Pages::RoutesPage
        end
      end

      private

      def static_apps = @static_apps ||= []
      def context = @context ||= [["", []]]
      def route_prefix = context.map(&:first).join
      def route_handler(handler) = build_rack_app(context[1..].flat_map(&:last), wrap_handler(handler))

      def root_app
        @root_app ||= begin
          builder = Rack::Builder.new
          context[0][1].each { |c, a, b| builder.use(c, *a, &b) }
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
          call_params = req.args.to_h { |k, v| [k.to_sym, v] }
          default_handler_params = { application: self, request: req, response: resp }
          handler.call(**call_params, **default_handler_params)
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

    # Hook into the app to define development routes and default middleware
    def self.inherited(subclass)
      super
      subclass.class_eval do
        subclass.setup_default_middleware
        subclass.setup_framework_routes if subclass.development?
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

    def all_routes # :nodoc:
      self.class.all_routes
    end

    private

    def handle_error(err)
      response.request_error = err
      handler = error_handler_for(err.class)
      handler.call(error: err, application: self, request: request, response: response)
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
