# frozen_string_literal: true

require_relative "lib/open_rosa/version"

Gem::Specification.new do |spec|
  spec.name = "open_rosa"
  spec.version = OpenRosa::VERSION
  spec.authors = ["Alex Watt"]
  spec.email = ["alex@alexcwatt.com"]

  spec.summary = "Manage OpenRosa forms."
  spec.homepage = "https://github.com/alexcwatt/openrosa-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alexcwatt/openrosa-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/alexcwatt/openrosa-ruby/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "nokogiri", "~> 1.15"
  spec.add_dependency "rack", "~> 3.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
