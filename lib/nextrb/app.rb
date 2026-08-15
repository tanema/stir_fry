# frozen_string_literal: true

require "rack"
require "mustermann"

module Nextrb
  # Request wraps Rack::Request with an addition of args that come from the url path
  class Request < Rack::Request
    attr_accessor :args
  end

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
      def get(pattern, options = nil, klass = nil, &block) = route("GET", pattern, options, klass, &block)
      def head(pattern, options = nil, klass = nil, &block) = route("HEAD", pattern, options, klass, &block)
      def options(pattern, options = nil, klass = nil, &block) = route("OPTIONS", pattern, options, klass, &block)
      def post(pattern, options = nil, klass = nil, &block) = route("POST", pattern, options, klass, &block)
      def put(pattern, options = nil, klass = nil, &block) = route("PUT", pattern, options, klass, &block)
      def patch(pattern, options = nil, klass = nil, &block) = route("PATCH", pattern, options, klass, &block)
      def delete(pattern, options = nil, klass = nil, &block) = route("DELETE", pattern, options, klass, &block)

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
      route, args = find_route(request)
      raise NotFound if route.nil?

      callable = route[2]
      result = if callable.is_a?(Proc)
                 Action.new(request, args).call(callable)
               else
                 callable.new(**args).call
               end
      puts "got result"
      result
    end

    def find_route(req)
      routes = self.class.routes[req.request_method] || []
      routes.each do |route|
        params = route[0].params(req.path_info)
        return [route, params] if params
      end
      [nil, nil]
    end

    def builder
      builder = Rack::Builder.new
      self.class.middleware.each { |c, a, b| builder.use(c, *a, &b) }
      builder.run(self)
      builder
    end
  end
end
