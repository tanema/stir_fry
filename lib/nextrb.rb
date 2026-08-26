# frozen_string_literal: true

require "rbx"

##
# Nextrb as a module provides an entrypoint to starting your app. It is also the
# namespace that contains the server library that will render the rbx templates.
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

  ##
  # Start the application server for an App.
  #
  # Example:
  #
  # ```ruby
  # class App < Nextrb::App
  #   get "/" { |req, resp| resp.text("Hello world") }
  # end
  #
  # Nextrb.run!(App)
  # ```
  def self.run!(app) = @server.run!(app)

  ##
  # Returns the running status of the server. If `run!` has not already been called
  # then this will return false.
  def self.running? = @server.running?

  ##
  # Stops the running server if it is running. If it is not running then this is
  # a no-op
  def self.quit! = @server.quit!
end
