# frozen_string_literal: true

module ActiveModule
  class InvalidModuleValue < StandardError
    def initialize(value, possible_modules)
      super(<<~ERROR_MESSAGE)
        "Invalid module value #{value.inspect}:#{" "}
         It must be one of:#{" "}
          #{possible_modules.inspect}
         or one of their demodulized names:
          #{possible_modules.map(&:name).map(&:demodulize).inspect}"
      ERROR_MESSAGE
    end
  end
end
