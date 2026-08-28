# frozen_string_literal: true

require "rbx"
require "rackup"
require "logger"

##
# Nextrb as a module provides an entrypoint to starting your app. It is also the
# namespace that contains the server library that will render the rbx templates.
module Nextrb
  class Error < StandardError; end
  class OKAY < Error; end
  class Found < Error; end
  class NotModified < Error; end
  class BadRequest < Error; end
  class NotFound < Error; end
  class Unauthorized < Error; end
  class InternalError < Error; end
  class PreconditionFailed < Error; end

  autoload :App, "nextrb/app"
  autoload :Component, "nextrb/component"
  autoload :Common, "nextrb/common"
  autoload :Pages, "nextrb/pages"
  autoload :Request, "nextrb/request"
  autoload :Response, "nextrb/response"
  autoload :Version, "nextrb/version"

  SIGNALS = %i[INT TERM].freeze

  @env = (ENV["APP_ENV"] || ENV["RACK_ENV"] || ENV["ENV"] || :development).to_sym
  @logger = ::Logger.new($stdout)

  class << self
    attr_reader :running_server, :env, :logger

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
    def run!(app_klass, **options)
      return unless running_server.nil?

      Rackup::Handler.default.run(app_klass, **options) do |server|
        at_exit { quit! }
        SIGNALS.each { |signal| chain_trap(signal) { quit! } }
        @running_server = server
      end
    ensure
      quit!
    end

    ##
    # Returns the running status of the server. If `run!` has not already been called
    # then this will return false.
    def running? = !running_server.nil?

    ##
    # Stops the running server if it is running. If it is not running then this is
    # a no-op
    def quit! = running_server.respond_to?(:stop!) ? running_server.stop! : running_server.stop

    private

    def chain_trap(sig, &)
      prev = Signal.trap(sig) do
        yield
        prev.call if prev.respond_to?(:call)
      end
    end
  end
end
