# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup
require "active_module/railtie" if defined?(Rails::Railtie)

module ActiveModule
  module_function

  def register!(type_symbol = :active_module)
    Register.call(type_symbol)
  end
end
