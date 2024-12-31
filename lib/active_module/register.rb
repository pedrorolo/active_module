# frozen_string_literal: true

require "active_model"

module ActiveModule
  module Register
    module_function

    def call(type_symbol = :active_module)
      ActiveModel::Type.register(type_symbol, ActiveModule::Base)
      return unless defined?(ActiveRecord::Type)

      require "active_record"
      ActiveRecord::Type.register(type_symbol, ActiveModule::Base)
    end
  end
end
