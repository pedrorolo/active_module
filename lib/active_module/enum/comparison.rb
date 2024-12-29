# frozen_string_literal: true

module ActiveModule
  class Enum
    module Comparison
      refine ::Module do
        using ActiveModule::Enum::ModuleRefinement

        def =~(other)
          case other
          when ::Symbol
            possible_symbol_names_set.include?(other)
          when ::String
            possible_symbol_names_set.include?(other.to_sym)
          else
            self == other
          end
        end
      end

      using self

      def self.compare(module1, module2)
        module1 =~ module2
      end
    end
  end
end
