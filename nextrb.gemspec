# frozen_string_literal: true

require_relative "lib/nextrb/version"

Gem::Specification.new do |spec|
  spec.name = "nextrb"
  spec.version = Nextrb::VERSION
  spec.authors = ["Tim Anema"]
  spec.email = ["timanema@gmail.com"]
  spec.summary = "Small simple ruby web framework that feels familiar."
  spec.description = <<~DESC
    Small simple ruby web framework that feels familiar.
    It leverages a JSX like templating language, simple routing definitions
    similar to sinatra and usage of ruby that will make it feel easy and understandable.
  DESC
  spec.homepage = "https://github.com/tanema/nextrb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"
  spec.require_paths = ["lib"]
  spec.metadata = {
    "source_code_uri"       => "https://github.com/tanema/nextrb",
    "changelog_uri"         => "https://github.com/tanema/nextrb/blob/main/CHANGELOG.md",
    "homepage_uri"          => spec.homepage,
    "bug_tracker_uri"       => "https://github.com/tanema/nextrb/issues",
    "documentation_uri"     => "https://github.com/tanema/nextrb",
    "rubygems_mfa_required" => "true"
  }
  spec.files = Dir["lib/**/*"] + [
    "README.md",
    "CHANGELOG.md",
    "CODE_OF_CONDUCT.md",
    "Gemfile",
    "LICENSE",
    "Rakefile",
    "nextrb.gemspec"
  ]

  spec.add_dependency "mustermann", "~> 3.0"
  spec.add_dependency "rack", ">= 3.0.0", "< 4"
  spec.add_dependency "rack-protection", ">= 3.1"
  spec.add_dependency "rack-session", ">= 2.0.0", "< 3"
  spec.add_dependency "rackup", ">= 2.1"
  spec.add_dependency "semantic_logger", ">= 5.1"
end
