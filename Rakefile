# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "rdoc/task"
require "rerun"

task default: %i[spec rubocop rdoc:coverage]

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["--require spec_helper"]
  t.verbose = ENV.fetch("VERBOSE", nil)
end

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.generator = "aliki"
  rdoc.rdoc_files.include(
    "lib/**/*.rb",
    "rbx/lib/**/*.rb",
    "CHANGELOG.md",
    "CODE_OF_CONDUCT.md",
    "README.md",
    "LICENSE"
  )
  rdoc.rdoc_dir = "docs"
  rdoc.markup = "markdown"
end

desc "Run an irb console with the library loaded"
task :console do
  require "nextrb"
  require "irb"
  ARGV.clear
  IRB.start
end
