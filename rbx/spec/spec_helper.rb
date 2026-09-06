# frozen_string_literal: true

require "bundler/setup"
require "rbx"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.max_formatted_output_length = nil
  end
end
