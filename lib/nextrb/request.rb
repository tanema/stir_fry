# frozen_string_literal: true

require "rack"
require "json"

module Nextrb
  # Request expands Rack::Request to include url args
  class Request < Rack::Request
    include Common

    attr_accessor :args

    def path = @path ||= Rack::Utils.unescape_path(path_info)
    def json? = accept?("application/json")
    def html? = accept?("text/html")
    def text? = accept?("text/plain")
    def xml? = accept?("application/xml")
    def csv? = accept?("text/csv")
    def accept?(mime) = accept_types.include?(mime)
    def forwarded? = !forwarded_authority.nil?
    def safe? = get? || head? || options? || trace?
    def idempotent? = safe? || put? || delete? || link? || unlink?
    def link? = request_method == "LINK"
    def unlink? = request_method == "UNLINK"
    alias secure? ssl?

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
