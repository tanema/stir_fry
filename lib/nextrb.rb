# frozen_string_literal: true

# Nextrb is the namespace that contains the library and is the main entrypoint
# to run the app.
module Nextrb
  class Error < StandardError; end
  class BadRequest < Error; end
  class NotFound < Error; end

  autoload :Version, "nextrb/version"
  autoload :Action, "nextrb/action"
  autoload :App, "nextrb/app"
  autoload :Server, "nextrb/server"
  autoload :Component, "nextrb/component"
  autoload :RBX, "nextrb/rbx"

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
