# frozen_string_literal: true

require "rack"
require "json"

module Nextrb
  # Action is a captured route
  class Action
    attr_reader :request, :response, :params

    CONTENT_TYPE = {
      json: "application/json",
      text: "text/plain",
      html: "text/html"
    }.freeze

    def initialize(request, args)
      @request = request
      @path = request.path_info
      @args = args
      @params = request.params
      @response = Rack::Response.new
    end

    def status(value = nil)
      response.status = Rack::Utils.status_code(value) if value
      response.status
    end

    def ok(message = "OK")
      status(:ok)
      text(message)
    end

    def bad_request(message = "Bad Request")
      status(:bad_request)
      text(message)
    end

    def not_found(message = "Not Found")
      status(:not_found)
      text(message)
    end

    def unauthorized(message = "Unauthorized")
      status(:unauthorized)
      text(message)
    end

    def redirect(uri)
      status(:found)
      response["Location"] = uri.to_s
    end

    def text(message)
      content_type(:text)
      response.body = [message]
    end

    def json(obj)
      content_type(:json)
      response.body = [JSON.dump(obj)]
    end

    def content_type(kind)
      response["Content-Type"] = CONTENT_TYPE[kind] || "text/html"
    end

    def call(block)
      instance_eval(&block)
      response.to_a
    end
  end
end
