# frozen_string_literal: true

require "rackup"

module Nextrb
  # Server manages a rack instance to actually run the rack app with the Nextrb::App
  class Server
    SIGNALS = %i[INT TERM].freeze

    attr_reader :app, :running_server

    def run!(app_klass)
      return unless running_server.nil?

      Rackup::Handler.default.run(app_klass) do |server|
        at_exit { quit! }
        SIGNALS.each { |signal| chain_trap(signal) { quit! } }
        @running_server = server
      end
    ensure
      quit!
    end

    def running? = !running_server.nil?
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
