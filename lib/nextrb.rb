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
  class InternalError < Error; end

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

  def self.run!(app) = server.run!(app)
  def self.running? = server.running?
  def self.quit! = server.quit!
end
