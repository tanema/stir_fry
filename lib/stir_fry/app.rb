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

    # Route definition struct to define the structure of data needed for a route.
    Route = Struct.new(:verb, :path, :pattern, :handler, :description, :cooked)

    attr_accessor :request, :response, :env # :nodoc:

    class << self
      def routes = @routes ||= {} # :nodoc:
      def route_table = @route_table ||= [] # :nodoc:
      def user_routes = route_table.reject(&:cooked) # :nodoc:
      def framework_routes = route_table.select(&:cooked) # :nodoc:
      def root_route = (routes["GET"] ||= []).find { |route| route.path == "/" } # :nodoc:
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
      def get(pattern, klass = nil, ...) = route("GET", pattern, klass, ...)

      # Add a HEAD request route to the application
      def head(pattern, klass = nil, ...) = route("HEAD", pattern, klass, ...)

      # Add a OPTIONS request route to the application
      def options(pattern, klass = nil, ...) = route("OPTIONS", pattern, klass, ...)

      # Add a POST request route to the application
      def post(pattern, klass = nil, ...) = route("POST", pattern, klass, ...)

      # Add a PUT request route to the application
      def put(pattern, klass = nil, ...) = route("PUT", pattern, klass, ...)

      # Add a PATCH request route to the application
      def patch(pattern, klass = nil, ...) = route("PATCH", pattern, klass, ...)

      # Add a DELETE request route to the application
      def delete(pattern, klass = nil, ...) = route("DELETE", pattern, klass, ...)

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
      def static(dirname, path: "/", **options)
        options ||= {}
        files = Rack::Files.new(File.expand_path(dirname))
        path = route_prefix + path
        route_table << Route.new(
          verb: "STATIC",
          path: "#{path}:asset_path",
          **options.slice(:cooked, :description)
        )
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
      def route(verb, pattern, klass, **options, &block)
        path = (route_prefix + pattern).sub(%r{(^.+)/$}, "\\1")
        options ||= {}
        route_table << Route.new(
          verb:, path:,
          pattern: Mustermann.new(path),
          handler: route_handler(klass || block),
          **options.slice(:cooked, :description)
        )
        (routes[verb] ||= []) << route_table.last
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
        return unless development?

        static File.join(__dir__, "static"), description: "StirFry static assets.", cooked: true
        scope "/stir_fry" do
          get "/", Pages::Welcome, description: "Default landing page for StirFry.", cooked: true
          get "/routes", Pages::RoutesPage, description: "List of all registered routes.", cooked: true
        end
        default_root_route
      end

      def default_root_route # :nodoc:
        return unless root_route.nil?

        get "/", description: "Redirect to welcome if you haven't defined a root route yet.",
                 cooked: true do |response:, **|
          response.redirect("/stir_fry")
        end
      end

      private

      def static_apps = @static_apps ||= []
      def context = @context ||= [["", []]]
      def route_prefix = context.map(&:first).join
      def route_handler(handler) = build_rack_app(context[1..].flat_map(&:last), wrap_handler(handler))

      def root_app
        @root_app ||= begin
          setup_default_middleware
          setup_framework_routes
          builder = Rack::Builder.new
          context[0][1].each { |c, a, b| builder.use(c, *a, &b) }
          builder.run(Rack::Cascade.new(static_apps + [->(env) { new(env).call }]))
          builder.to_app
        end
      end

      def wrap_handler(handler)
        lambda do |env|
          request = env.fetch(REQUEST_ENV_KEY)
          response = env.fetch(RESPONSE_ENV_KEY)
          verb = request.request_method.downcase.to_sym
          handler = handler.method(verb) if handler.respond_to?(verb)
          call_params = request.args.to_h { |k, v| [k.to_sym, v] }
          default_handler_params = { application: self, request: , response: , env: }
          handler.call(**call_params, **default_handler_params)
          response.finish
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
    def route_table = self.class.route_table # :nodoc:
    def user_routes = self.class.user_routes # :nodoc:
    def framework_routes = self.class.framework_routes # :nodoc:

    def call # :nodoc:
      find_route.call(env)
    rescue StandardError => e
      handle_error(e)
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
        params = route.pattern.params(request.path_info)
        request.args = params if params
        return route.handler if params
      end
      raise NotFound
    end
  end
end
