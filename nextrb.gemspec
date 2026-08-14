# frozen_string_literal: true

require_relative "lib/nextrb/version"

Gem::Specification.new do |spec|
  spec.name = "nextrb"
  spec.version = Nextrb::VERSION
  spec.authors = ["Tim Anema"]
  spec.email = ["timanema@gmail.com"]
  spec.summary = "Small simple ruby web framework that feels familiar."
  spec.description = "Small simple ruby web framework that feels familiar."
  spec.homepage = "https://github.com/tanema/nextrb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"
  spec.require_paths = ["lib"]
  spec.metadata = {
    allowed_push_host: "TODO: Set to your gem server 'https://example.com'",
    source_code_uri: "https://github.com/tanema/nextrb",
    changelog_uri: "https://github.com/tanema/nextrb/blob/main/CHANGELOG.md",
    homepage_uri: spec.homepage,
    bug_tracker_uri: "https://github.com/tanema/nextrb/issues",
    documentation_uri: "https://github.com/tanema/nextrb",
    rubygems_mfa_required: "true"
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
end
