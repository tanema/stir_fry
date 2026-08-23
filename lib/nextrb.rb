# frozen_string_literal: true

require "rbx"

# Nextrb is the namespace that contains the library and is the main entrypoint
# to run the app.
module Nextrb
  class Error < StandardError; end
  class OKAY < Error; end
  class BadRequest < Error; end
  class NotFound < Error; end
  class Unauthorized < Error; end

  autoload :App, "nextrb/app"
  autoload :Component, "nextrb/component"
  autoload :Pages, "nextrb/pages"
  autoload :Request, "nextrb/request"
  autoload :Response, "nextrb/response"
  autoload :Server, "nextrb/server"
  autoload :Version, "nextrb/version"

  @server = Server.new
  class << self
    attr_reader :server
  end

  def self.run!(app)
    server.run!(app)
  end

  def self.quit!
    return if server.nil?

    server.respond_to?(:stop!) ? server.stop! : server.stop
  end
end
