# frozen_string_literal: true

require "optparse"
require "fileutils"

module StirFry
  module CLI
    class New # :nodoc:
      attr_accessor :options

      def self.call = new.call

      def call
        parse_options!
        generate_template!
        initialize_project!
      end

      private

      def project_dir 
        File.join(Dir.pwd, options[:name])
      end

      # rubocop:disable Metrics/MethodLength
      def parse_options!
        self.options = {}
        option_parser = OptionParser.new do |o|
          o.banner = "Usage: stirfry new [options]"
          o.separator ""
          o.separator "Generate a new stirfry app."
          o.separator ""
          o.separator "Options:"
          o.on("-n name", "--name name", "Specify your app name") { |name| options[:name] = name }
          o.on_tail("-h", "--help", "Prints this help") do
            puts o
            exit
          end
        end
        option_parser.order!

        abort("--name option required") if options[:name].nil?
        options
      end
      # rubocop:enable Metrics/MethodLength

      def generate_template!
        FileUtils.mkdir_p(project_dir)
        Dir.glob(File.join(__dir__, "template", "*")) { |path| FileUtils.cp_r(path, project_dir) }
      end

      def initialize_project!
        Dir.chdir(project_dir) do
          system("bundle install")
          system("bundle exec rspec --init")
          system("bundle exec rubocop --init")
        end
      end
    end
  end
end
