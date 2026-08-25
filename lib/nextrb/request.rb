# frozen_string_literal: true

require "rack"
require "json"

module Nextrb
  # Request expands Rack::Request to include url args
  class Request < Rack::Request
    attr_accessor :args

    def path = @path ||= Rack::Utils.unescape_path(path_info)
    def json? = accept?("application/json")
    def html? = accept?("text/html")
    def text? = accept?("text/plain")
    def xml? = accept?("application/xml")
    def csv? = accept?("text/csv")
  end
end
