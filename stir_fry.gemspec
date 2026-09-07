# frozen_string_literal: true

require_relative "lib/stir_fry/version"

Gem::Specification.new do |spec|
  spec.name = "stir_fry"
  spec.version = StirFry::VERSION
  spec.authors = ["Tim Anema"]
  spec.email = ["timanema@gmail.com"]
  spec.summary = "Small simple ruby web framework that feels familiar."
  spec.description = <<~DESC
    Small simple ruby web framework that feels familiar.
    It leverages a JSX like templating language, simple routing definitions
    similar to sinatra and usage of ruby that will make it feel easy and understandable.
  DESC
  spec.post_install_message = " 🐦‍⬛ Let's Get Cookin! 🥡 "
  spec.homepage = "https://github.com/tanema/stir_fry"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"
  spec.require_paths = ["lib"]
  spec.bindir        = "bin"
  spec.executables   = ["stirfry"]
  spec.metadata = {
    "source_code_uri" => "https://github.com/tanema/stir_fry",
    "changelog_uri" => "https://github.com/tanema/stir_fry/blob/main/CHANGELOG.md",
    "homepage_uri" => spec.homepage,
    "bug_tracker_uri" => "https://github.com/tanema/stir_fry/issues",
    "documentation_uri" => "https://github.com/tanema/stir_fry",
    "rubygems_mfa_required" => "true"
  }
  spec.files = Dir["lib/**/*"] + [
    "bin/stirfry",
    "README.md",
    "CHANGELOG.md",
    "CODE_OF_CONDUCT.md",
    "Gemfile",
    "LICENSE",
    "Rakefile",
    "stir_fry.gemspec"
  ]

  spec.add_dependency "mustermann", "~> 3.0"
  spec.add_dependency "rack", ">= 3.0.0", "< 4"
  spec.add_dependency "rack-protection", ">= 3.1"
  spec.add_dependency "rack-session", ">= 2.0.0", "< 3"
  spec.add_dependency "rbxrb", ">= 0.1"
  spec.add_dependency "semantic_logger", ">= 5.1"
end
