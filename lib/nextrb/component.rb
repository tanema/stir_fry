# frozen_string_literal: true

module Nextrb
  # Component is a single request/response view handler.
  class Component
    include RBX::Component

    attr_reader :request, :response

    def self.call(req, resp, **args)
      new(**args).call(req, resp)
    end

    def call(request, response)
      @request = request
      @response = response
      response.html(render)
    end
  end
end
