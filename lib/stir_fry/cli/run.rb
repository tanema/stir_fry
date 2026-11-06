# frozen_string_literal: true

require "optparse"
require "listen"

module StirFry
  module CLI
    class Run # :nodoc:
      attr_accessor :pid, :listener, :options

      def self.call = new.call

      def call
        start_puma
        listen
        sleep 0.5 while listener.processing?
      ensure
        kill_puma
      end

      private

      # rubocop:disable Metrics/MethodLength
      def parse_options!
        self.options = {}
        option_parser = OptionParser.new do |o|
          o.banner = "Usage: stirfry run [options]"
          o.separator ""
          o.separator "Watch for file changes and restart the app when project files change."
          o.separator ""
          o.separator "Options:"
          o.on_tail("-h", "--help", "Prints this help") do
            puts o
            exit
          end
        end
        option_parser.order!
      end
      # rubocop:enable Metrics/MethodLength

      def listen
        self.listener = Listen.to(Dir.pwd) do |_modified, _added, _removed|
          restart_puma
        end
        listener.start
      end

      def start_puma
        return unless pid.nil?

        self.pid = Process.spawn("bundle exec rackup")
      end

      def kill_puma
        return if pid.nil?

        Process.kill("TERM", pid)
        Process.wait(pid)
        nil
      end

      def restart_puma
        kill_puma
        start_puma
      end
    end
  end
end
