# frozen_string_literal: true

require "semantic_logger"
require "rbx"
require "rackup"
require "logger"

##
# Nextrb as a module provides an entrypoint to starting your app. It is also the
# namespace that contains the server library that will render the rbx templates.
module Nextrb
  # Error is the main root error for most errors raised by the library. Most of these
  # errors are raised to bail out of a request cycle early and return early.
  class Error < StandardError; end
  # Okay represents a http 200 response.
  class OKAY < Error; end
  # Found represents a http 302 response.
  class Found < Error; end
  # NotModified represents a http 304 response.
  class NotModified < Error; end
  # BadRequest represents a http 400 response.
  class BadRequest < Error; end
  # Unauthorized represents a http 401 response.
  class Unauthorized < Error; end
  # NotFound represents a http 404 response.
  class NotFound < Error; end
  # PreconditionFailed represents a http 412 response.
  class PreconditionFailed < Error; end
  # InternalError represents a http 500 response.
  class InternalError < Error; end

  autoload :App, "nextrb/app"
  autoload :Component, "nextrb/component"
  autoload :Pages, "nextrb/pages"
  autoload :Request, "nextrb/request"
  autoload :Response, "nextrb/response"
  autoload :Middleware, "nextrb/middleware"
  autoload :Version, "nextrb/version"

  SIGNALS = %i[INT TERM].freeze # :nodoc:

  class << self
    attr_reader :running_server # :nodoc:

    ##
    # Start the application server for an App.
    #
    # Example:
    #
    # ```ruby
    # class App < Nextrb::App
    #   get "/" { |request:, response:| response.text("Hello world") }
    # end
    #
    # Nextrb.run!(App)
    # ```
    #
    # Options:
    #
    # - port       [int]    port to listen on for the server.
    #                       Defaults to 8080 in development and 80 in production.
    # - host       [string] host to bind on.
    #                       Default to `localhost` in development and `0.0.0.0` in production
    # - logger     [Logger] logger to output requests and app messages to.
    #                       Defaults to new semantic logger.
    # - log_level  [Symbol] the log level or limit output of the log.
    #                       options: (:trace, :debug, :info, :warn, :error, :fatal)
    #                       default: :trace in development and :info in production.
    # - log_format [Symbol] the output format of the semantic logger.
    #                       options: (:default, :color, :json, :logfmt)
    # - log_stdout          disable stdout logging.
    #                       default: true
    # - log_file            set a filepath to output logs to.
    #                       default: nil, only outputs to stdout.
    #
    def run!(app_klass, **options)
      return unless running_server.nil?

      Rackup::Handler.default.run(app_klass, **extract_options(app_klass, **options)) do |server|
        at_exit { quit! }
        SIGNALS.each { |signal| chain_trap(signal) { quit! } }
        @logger.info("Server started", **server_info(server))
        server.threaded = true if server.respond_to? :threaded=
        @running_server = server
      end
    ensure
      quit!
    end

    ##
    # Returns the running status of the server. If `run!` has not already been called
    # then this will return false.
    def running? = !running_server.nil?

    # Is the set environment setting evaluated from environment variables APP_ENV,
    # RACK_ENV or ENV. It defaults to :development.
    def app_env = @app_env ||= (ENV["APP_ENV"] || ENV["RACK_ENV"] || ENV["ENV"] || :development).to_sym

    # is the app running in development.
    def development? = app_env == :development

    # is the app running in test.
    def test? = app_env == :test

    # is the app running in production
    def production? = app_end == :production

    # Logger is the app wide logger for any app messages.
    def logger = @logger ||= default_logger(App)

    ##
    # Stops the running server if it is running. If it is not running then this is
    # a no-op
    def quit!
      return if running_server.nil?

      running_server.respond_to?(:stop!) ? running_server.stop! : running_server.stop
    end

    private

    def extract_options(klass, **options)
      @port = options.fetch(:Port, options.fetch(:port, default_port)) || default_port
      @host = options.fetch(:Host, options.fetch(:host, default_host)) || default_host
      @logger = options.delete(:logger) || default_logger(klass, options)
      dev_null = Logger.new(File.open(File::NULL, "w"))
      {
        # Set the capitalized options in case the downcased options are set.
        Port: @port,
        Host: @host,
        # Disable Rack logging
        Logger: dev_null,
        AccessLog: dev_null
      }.merge(options)
    end

    def server_info(server)
      {
        port: @port,
        host: @host,
        app_env: @app_env,
        threaded: server.respond_to?(:threaded=),
        server: Rackup::Handler.default.name
      }
    end

    def default_logger(klass, options = {})
      log_format = options.fetch(:log_format, :color) || :color
      log_stdout = options.fetch(:log_silence, false)
      log_file = options.fetch(:log_file, nil)

      SemanticLogger.add_signal_handler
      SemanticLogger.application = klass.name.to_s
      SemanticLogger.environment = @app_env
      SemanticLogger.default_level = options.fetch(:log_level, default_log_level) || default_log_level
      SemanticLogger.add_appender(io: $stdout, formatter: log_format) unless log_stdout
      SemanticLogger.add_appender(filename: log_file, formatter: log_format) unless log_file.nil?
      SemanticLogger[klass.name.to_s]
    end

    def default_port
      development? ? "8080" : "80"
    end

    def default_host
      development? ? "localhost" : "0.0.0.0"
    end

    def default_log_level
      development? ? :trace : :info
    end

    def chain_trap(sig, &)
      prev = Signal.trap(sig) do
        yield
        prev.call if prev.respond_to?(:call)
      end
    end
  end
end
