module ActiveModule
  module Comparision
    refine ::Module do
      using ActiveModule::ModuleRefinement

      def ==(other)
        case other
        when nil
          false
        when ::Module
          super(other)
        when ::String
          (@possible_names ||= possible_names).include?(other)
        when ::Symbol
          (@possible_names ||= possible_names).include?(other.to_s)
        else
          false
        end
      end
    end
  end
end
