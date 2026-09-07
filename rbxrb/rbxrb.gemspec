# frozen_string_literal: true

require_relative "lib/rbx/version"

Gem::Specification.new do |spec|
  spec.name = "rbxrb"
  spec.version = RBX::VERSION
  spec.authors = ["Tim Anema"]
  spec.email = ["timanema@gmail.com"]
  spec.summary = "A ruby templating language similar to JSX."
  spec.description = <<~DOC
    A ruby templating language similar to JSX that compiles to a ruby function.
    It allows for defining that function on a class that can then define variables
    and methods that can be used in the template.
  DOC
  spec.homepage = "https://github.com/tanema/nextrb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"
  spec.require_paths = ["lib"]
  spec.metadata = {
    "source_code_uri" => "https://github.com/tanema/nextrb",
    "changelog_uri" => "https://github.com/tanema/nextrb/blob/main/rbx/CHANGELOG.md",
    "homepage_uri" => spec.homepage,
    "bug_tracker_uri" => "https://github.com/tanema/nextrb/issues",
    "documentation_uri" => "https://github.com/tanema/nextrb",
    "rubygems_mfa_required" => "true"
  }
  spec.files = Dir["lib/**/*"] + [
    "README.md",
    "CHANGELOG.md",
    "Gemfile",
    "Rakefile",
    "rbxrb.gemspec"
  ]

  spec.add_dependency "rack", ">= 3.0.0", "< 4"
end
