# frozen_string_literal: true

require "rack"
require "mustermann"

module Nextrb
  class Request < Rack::Request
    attr_accessor :args
  end

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
      def use(middleware, *args, &block) = middleware.<<([middleware, args, block])
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
      routes = self.class.routes[request.request_method]
      route = routes&.find { |route| route[0].match(request.path_info) }
      raise NotFound if route.nil?

      action = Action.new(request, route[0].params(request.path_info))
      action_res = action.call(route[2])
      action.response.body = [action_res] unless action_res.nil?
      action.response.to_a
    end

    def builder
      builder = Rack::Builder.new
      @middleware&.each { |c, a, b| builder.use(c, *a, &b) }
      builder.run(self)
      builder
    end
  end
end
