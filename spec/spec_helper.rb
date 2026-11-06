# frozen_string_literal: true

require "simplecov"
SimpleCov.minimum_coverage 100
SimpleCov.start
require "active_record"
require "active_support/logger"
require "active_module"
require "byebug"

unless defined?(Rails)
  module Rails
    class << self
      attr_accessor :logger
    end
  end
end
Rails.logger ||= ActiveSupport::Logger.new($stderr)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
