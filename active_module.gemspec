# frozen_string_literal: true

require_relative "lib/active_module/version"

Gem::Specification.new do |spec|
  github_url = "https://github.com/pedrorolo/active_module"
  spec.name = "active_module"
  spec.version = ActiveModule::VERSION
  spec.authors = ["Pedro Rolo"]
  spec.email = ["pedrorolo@gmail.com"]

  spec.summary = "Module type for ActiveModel and Active Record"
  spec.description = "Module type for ActiveModel and Active Record"
  spec.homepage = github_url
  spec.required_ruby_version = ">= 3.0.0"

  #  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = github_url
  spec.metadata["source_code_uri"] = github_url
  #  spec.metadata["changelog_uri"] = github_url

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been
  # added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__,
                                             err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ spec/ features/ .git .github Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  #   s.add_dependency "activesupport", version
  spec.add_dependency "activerecord", "~> 7.0"
  spec.add_dependency "bundler", ">= 1.15.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
