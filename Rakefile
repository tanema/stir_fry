# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["--require spec_helper"]
  t.verbose = ENV.fetch("VERBOSE", nil)
end
RuboCop::RakeTask.new

task default: %i[spec rubocop]
