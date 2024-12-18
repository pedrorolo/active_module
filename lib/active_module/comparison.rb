# frozen_string_literal: true

module ActiveModule
  module Comparison
    refine ::Module do
      using ActiveModule::ModuleRefinement

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

      private

      def possible_symbol_names_set
        @possible_symbol_names_set ||= Set.new(possible_names.map(&:to_sym))
      end
    end

    using self

    def self.compare(module1, module2)
      module1 =~ module2
    end
  end
end
