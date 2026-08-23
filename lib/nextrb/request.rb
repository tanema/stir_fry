# frozen_string_literal: true

require "rack"
require "json"

module Nextrb
  # Request expands Rack::Request to include url args
  class Request < Rack::Request
    attr_accessor :args

    def path = @path ||= Rack::Utils.unescape_path(path_info)
    def json? = accept.include?("application/json")
    def html? = accept.include?("text/html")
    def text? = accept.include?("text/plain")
    def accept = @accept ||= parse_http_accept_header(get_header("HTTP_ACCEPT"))

    private

    def parse_http_accept_header(header)
      return if header.nil?

      puts "HEADER #{header.to_s.split(",").first}"
      header.to_s.split(",").filter_map do |part|
        part.strip!
        next if part.empty?

        part.split(";", 2).first
      end
    end
  end
end
