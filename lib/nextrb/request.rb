# frozen_string_literal: true

require "rack"
require "json"

module Nextrb
  # Request expands Rack::Request to include url args
  class Request < Rack::Request
    attr_accessor :args

    def path
      @path ||= Rack::Utils.unescape_path path_info
    end
  end
end
