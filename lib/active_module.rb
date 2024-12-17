# frozen_string_literal: true

require_relative "active_module/version"
require_relative "active_module/base"
require_relative "active_module/invalid_module_value"
require_relative "active_module/register"
require_relative "active_module/comparison"
require "active_module/railtie" if defined?(Rails::Railtie)

module ActiveModule
  module_function

  def register!(type_symbol = :active_module)
    Register.call(type_symbol)
  end
end
