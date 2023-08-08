# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "logging-honeybadger"
  spec.version = "0.0.1"
  spec.authors = ["Skye Shaw"]
  spec.email = ["skye.shaw@gmail.com"]

  spec.summary       = %q{Honeybadger appender for the Logging gem}
  spec.description   = %q{An appender for the Logging gem that sends all messages logged at the :error level to Honeybadger}
  spec.homepage      = "https://github.com/sshaw/logging-honeybadger"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sshaw/logging-honeybadger"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Maybe less, but only tested with v5
  spec.add_dependency "honeybadger", "~> 5.0"
  spec.add_dependency "logging"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.0", "<5.16"
end
