# frozen_string_literal: true

module ActiveModule
  class Enum
    module ModuleRefinement
      refine ::Module do
        using ActiveModule::ModuleRefinement

        def possible_names
          overriden_possible_names
        end

        def enum_symbol
          name.demodulize.underscore.to_sym
        end

        def possible_symbol_names_set
          @possible_symbol_names_set ||=
            Set.new(overriden_possible_names.map(&:to_sym))
        end

        private

        def overriden_possible_names
          [enum_symbol.to_s] + possible_names
        end
      end

      using self
    end
  end
end
