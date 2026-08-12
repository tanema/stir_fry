# frozen_string_literal: true

require "rackup"

module Nextrb
  class Server
    attr_reader :app, :running_server

    def run!(app)
      Rackup::Handler.default.run(app.builder) do |server|
        handle_traps
        @running_server = server
      end
    ensure
      quit!
    end

    def handle_traps
      at_exit { quit! }

      %i[INT TERM].each do |signal|
        old_handler = trap(signal) do
          quit!
          old_handler.call if old_handler.respond_to?(:call)
        end
      end
    end

    def quit!
      running_server.respond_to?(:stop!) ? running_server.stop! : running_server.stop
    end
  end
end
