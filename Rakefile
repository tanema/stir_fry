# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "rdoc/task"
require "rerun"

task default: %i[spec rubocop]

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["--require spec_helper"]
  t.verbose = ENV.fetch("VERBOSE", nil)
end

RDoc::Task.new do |rdoc|
  rdoc.main = "docs/index.md"
  rdoc.generator = "aliki"
  rdoc.rdoc_files.include("lib/**/*.rb")
  rdoc.rdoc_dir = "docs/reference"
  rdoc.markup = "markdown"
end

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
  Rerun::Runner.keep_running("./bin/run ./example/app.rb", {})
end
