# frozen_string_literal: true

require "optparse"
require "pathname"

module StirFry
  module CLI
    class Options # :nodoc:
      # rubocop:disable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize
      def self.parse!(args: ARGV)
        options = { rerun: {}, rackup: {} }

        option_parser = OptionParser.new("", 24, "  ") do |o|
          o.banner = "Usage: stirfry [options] [application_directory]"

          o.separator ""
          o.separator "Uses the rerun gem and rackup to run your development app and reload it when needed."
          o.separator "Version: #{StirFry::VERSION}"

          o.separator ""
          o.separator "Options:"
          o.on("-d dir", "--dir dir",
               "directory to watch. Specify multiple paths with ',' or separate '-d dir' " \
               "option pairs. (default ./ )") do |dir|
            (options[:rerun][:dir] ||= []).concat(dir.split(","))
          end
          o.on("-p pattern", "--pattern pattern", "file glob to watch, (default \"**/*\")") do |pattern|
            options[:rerun][:pattern] = pattern
          end
          o.on("-i pattern", "--ignore pattern", "file glob(s) to ignore.") do |pattern|
            (options[:rerun][:ignore] ||= []) << pattern
          end
          o.on("-n name", "--name name",
               "name of app used in logs and notifications (default \"#{rerun_defaults[:name]}\")") do |name|
            options[:rerun][:name] = name
          end
          o.on("--notify", "send messages through a desktop notification application.") do
            options[:rerun][:notify] = os_notifier
          end
          o.on("-o", "--host HOST", "listen on HOST (default: #{rackup_defaults[:host]})") do |host|
            options[:rackup][:host] = host
          end
          o.on("-p", "--port PORT", "use PORT (default: #{rackup_defaults[:port]})") do |port|
            options[:rackup][:port] = port
          end
          o.on("-v", "--verbose", "output more logs") { options[:rerun][:verbose] = options[:verbose] = true }
          o.on("-w", "--warn", "turn warnings on for your script") { options[:rerun][:warn] = options[:warn] = true }
          o.on("-q", "--quiet", "turn off logging") { options[:rerun][:quiet] = options[:quiet] = true }
          o.on_tail("--config config_filepath", "load config from path (default: .stirfry)") do |value|
            options[:config] = value
          end
          o.on_tail("-h", "--help", "--usage", "show this message") do
            puts o
            return {}
          end
          o.on_tail("--version", "show version") do
            puts StirFry::VERSION
            return {}
          end
        end

        begin
          option_parser.parse! args
        rescue OptionParser::InvalidOption => e
          warn e.message
          abort option_parser.to_s
        end

        options[:rackup] = rackup_defaults.dup.merge(options[:rackup])
        options[:rerun] = rerun_defaults.dup.merge(options[:rerun])
        options[:config] ||= ".stirfry"
        options[:app_directory] = args.last && !args.last.empty? ? args.last.strip : "."
        options[:rackup_file] = File.expand_path("config.ru", options[:app_directory])
        options
      end
      # rubocop:enable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize

      def self.validate_enum!(opt_name, enum)
        raise OptionParser::InvalidOption, "unknown #{opt_name}: #{e}" unless enum.include?(e)
      end

      def self.mac? = RUBY_PLATFORM =~ /darwin/i
      def self.windows? = RUBY_PLATFORM =~ /(mswin|mingw32)/i
      def self.linux? = RUBY_PLATFORM =~ /linux/i

      def self.rackup_defaults
        @rackup_defaults ||= {
          host: "localhost",
          port: 9292
        }
      end

      def self.rerun_defaults
        {
          dir: [+"."],
          ignore: [],
          name: Pathname.getwd.basename.to_s.tr("_-", " ").split.map(&:capitalize).join(" "),
          notify: false,
          pattern: "**/*",
          clear: true,
          wait: 2,
          signal: "TERM,INT,KILL"
        }
      end

      def self.os_notifier
        return "osx" if mac?
        return "notify-send" if linux?

        warn "no notifier supported for windows" if windows?
        nil
      end
    end
  end
end
