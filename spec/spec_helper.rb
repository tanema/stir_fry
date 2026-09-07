# frozen_string_literal: true

require "bundler/setup"
require "stir_fry"
require_relative "fixtures/button"

# Keep the request/server logs out of the spec output. Both the memoized
# StirFry.logger and the one StirFry.run! builds itself funnel through
# default_logger, so overriding it here silences every code path.
module SilentLogger
  def default_logger(klass, _options = {})
    name = klass.respond_to?(:name) ? klass.name.to_s : klass.to_s
    SemanticLogger[name]
  end
end
StirFry.singleton_class.prepend(SilentLogger)

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.max_formatted_output_length = nil
  end
end
