# frozen_string_literal: true

module ActiveModule
  module Register
    module_function

    def call(type_symbol = :active_module)
      ActiveModel::Type.register(type_symbol, ActiveModule::Base)
      ActiveRecord::Type.register(type_symbol, ActiveModule::Base)
    end
  end
end
