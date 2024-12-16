# frozen_string_literal: true

module ActiveModule
  module ModuleRefinement
    refine ::Module do
      def possible_names
        name_parts = name.split("::")
        [qualified_name].tap do |possible_names|
          loop do
            possible_names << name_parts.join("::").freeze
            name_parts = name_parts.drop(1)
            break if name_parts.empty?
          end
        end
      end

      def qualified_name
        "::#{name}"
      end
    end
  end
end
