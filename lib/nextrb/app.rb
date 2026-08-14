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
      def use(middleware, *args, &block) = middleware << [middleware, args, block]
      def get(pattern, options = {}, &block) = route("GET", pattern, options, block)
      def head(pattern, options = {}, &block) = route("HEAD", pattern, options, block)
      def options(pattern, options = {}, &block) = route("OPTIONS", pattern, options, block)
      def post(pattern, options = {}, &block) = route("POST", pattern, options, block)
      def put(pattern, options = {}, &block) = route("PUT", pattern, options, block)
      def patch(pattern, options = {}, &block) = route("PATCH", pattern, options, block)
      def delete(pattern, options = {}, &block) = route("DELETE", pattern, options, block)

      def route(verb, pattern, options, block)
        options ||= {}
        path_options = options.fetch(:path_options, {})
        route_pat = Mustermann.new(pattern, **path_options)
        (routes[verb] ||= []) << [route_pat, options, block]
      end

      def routes
        @routes ||= {}
      end

      def middleware
        @middleware ||= []
      end
    end

    def call(env)
      request = Request.new(env)
      route = find_route(request)
      raise NotFound if route.nil?

      Action.new(request, route[0].params(request.path_info)).call(route[2])
    end

    def find_route(req)
      self.class.routes[req.request_method]&.find { |route| route[0].match(req.path_info) }
    end

    def builder
      builder = Rack::Builder.new
      @middleware&.each { |c, a, b| builder.use(c, *a, &b) }
      builder.run(self)
      builder
    end
  end
end
