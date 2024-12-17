# frozen_string_literal: true

module ActiveModule
  class Railtie < Rails::Railtie
    initializer "active_module.register_attribute" do
      ActiveModule::Register.call
    end
  end
end
