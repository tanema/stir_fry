# frozen_string_literal: true

require "rackup"

module Nextrb
  # Server manages a rack instance to actually run the rack app with the Nextrb::App
  class Server
    attr_reader :app, :running_server

    def run!(app_klass)
      builder = Rack::Builder.new
      app_klass.middleware.each { |c, a, b| builder.use(c, *a, &b) }
      builder.run(app_klass.new)
      Rackup::Handler.default.run(builder) do |server|
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
