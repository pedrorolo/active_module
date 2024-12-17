# frozen_string_literal: true

module ActiveModule
  class Railtie < Rails::Railtie
    initializer "my_gem.configure_rails_initialization" do
      ActiveModule::Register.call
    end
  end
end
