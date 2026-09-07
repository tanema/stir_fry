# frozen_string_literal: true

require "semantic_logger"
require "rbx"
require "rackup"
require "logger"

##
# StirFry as a module provides an entrypoint to starting your app. It is also the
# namespace that contains the server library that will render the rbx templates.
module StirFry
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

  autoload :App, "stir_fry/app"
  autoload :CLI, "stir_fry/cli"
  autoload :Component, "stir_fry/component"
  autoload :Pages, "stir_fry/pages"
  autoload :Request, "stir_fry/request"
  autoload :Response, "stir_fry/response"
  autoload :Middleware, "stir_fry/middleware"
  autoload :VERSION, "stir_fry/version"

  SIGNALS = %i[INT TERM].freeze # :nodoc:

  class << self
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
    def logger = @logger ||= default_logger

    private

    def default_logger
      SemanticLogger.add_signal_handler
      SemanticLogger.application = "StirFry"
      SemanticLogger.environment = app_env
      SemanticLogger.default_level = :trace
      SemanticLogger.add_appender(io: $stdout, formatter: :color)
      SemanticLogger["StirFry"]
    end
  end
end
