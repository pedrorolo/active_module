# frozen_string_literal: true

module ActiveModule
  module Comparison
    refine ::Module do
      using ActiveModule::ModuleRefinement

      def =~(other)
        case other
        when ::String
          (@possible_names ||= possible_names).include?(other)
        when ::Symbol
          (@possible_names ||= possible_names).include?(other.to_s)
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
