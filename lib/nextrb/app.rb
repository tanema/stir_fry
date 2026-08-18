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

        # send_file path, options.merge(disposition: nil)
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

    def call(env)
      request = Request.new(env)
      response = Response.new(env)
      handler, _, request.args = find_route(request)
      raise NotFound if handler.nil?

      verb = request.request_method.downcase.to_sym
      handler = handler.method(verb) if handler.respond_to?(verb)
      handler.call(request, response)
      response.finish
    end

    def find_route(req)
      puts "VERB: #{req.request_method} ROUTES: #{self.class.routes[req.request_method]}"
      routes = self.class.routes[req.request_method] || []
      routes.each do |route|
        params = route[0].params(req.path_info)
        return [route[2], route[1], params] if params
      end
      [nil, nil, nil]
    end

    def builder
      builder = Rack::Builder.new
      self.class.middleware.each { |c, a, b| builder.use(c, *a, &b) }
      builder.run(self)
      builder
    end
  end
end
