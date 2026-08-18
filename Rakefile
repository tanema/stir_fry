# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["--require spec_helper"]
  t.verbose = ENV.fetch("VERBOSE", nil)
end
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc "Run an irb console with the library loaded"
task :console do
  require "nextrb"
  require "irb"
  ARGV.clear
  IRB.start
end

desc "Run the example server"
task :run do
  require_relative "example/app"
end

desc "Run the example server and reload if there are changes"
task :watch do
  # rerun './bin/run ./example/app.rb'
end
