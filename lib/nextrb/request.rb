# frozen_string_literal: true

require "rack"
require "json"

module Nextrb
  # Request expands Rack::Request to include url args
  class Request < Rack::Request
    # args are the parameters that were parsed from the url path such as resource ids.
    attr_accessor :args

    # The unescaped path from the request.
    def path = @path ||= Rack::Utils.unescape_path(path_info)
    # Returns true if the request accepts json
    def json? = accept?("application/json")
    # Returns true if the request accepts html
    def html? = accept?("text/html")
    # Returns true if the request accepts text
    def text? = accept?("text/plain")
    # Returns true if the request accepts xml
    def xml? = accept?("application/xml")
    # Returns true if the request accepts csv
    def csv? = accept?("text/csv")
    # Returns true if the request accepts header matches a mime type string
    def accept?(mime) = accept_types.include?(mime)

    # params wraps rack:request params and captures common errors. This is copied
    # from Sinatra's handling of params.
    def params
      super
    rescue Rack::Utils::ParameterTypeError, Rack::Utils::InvalidParameterError => e
      raise BadRequest, "Invalid query parameters: #{Rack::Utils.escape_html(e.message)}"
    rescue EOFError => e
      raise BadRequest, "Invalid multipart/form-data: #{Rack::Utils.escape_html(e.message)}"
    end

    private

    def accept_types
      @accept_types ||= get_header("HTTP_ACCEPT").to_s.split(",").filter_map { |part| part.split(";", 2).first&.strip }
    end
  end
end
