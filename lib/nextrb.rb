# frozen_string_literal: true

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

  def self.run!(app)
    server.run!(app)
  end

  def self.quit!
    return if server.nil?

    server.respond_to?(:stop!) ? server.stop! : server.stop
  end

  def self.server
    @@server ||= Server.new
  end
end
