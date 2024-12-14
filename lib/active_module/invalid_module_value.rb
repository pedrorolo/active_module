# frozen_string_literal: true

module ActiveModule
  class InvalidModuleValue < StandardError
    def initialize(value,
                   possible_modules:,
                   possible_symbols:)
      super(<<~ERROR_MESSAGE)
        "Invalid active_module value #{value.inspect}:
         It must be one of these modules:
          #{possible_modules.inspect}

         Or one of their referring symbols
          #{possible_symbols.inspect}

         Or corresponding strings:
          #{possible_symbols.map(&:to_s).inspect}
      ERROR_MESSAGE
    end
  end
end
