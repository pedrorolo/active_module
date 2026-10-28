# frozen_string_literal: true

module ActiveModule
  module ModuleRefinement
    refine ::Module do
      def possible_names
        underscored_names + colon_delimited_names
      end

      def possible_symbol_names_set
        @possible_symbol_names_set ||=
          Set.new(possible_names.map(&:to_sym))
      end

      def qualified_name
        "::#{name}"
      end

      def underscored_names
        parts = name.split("::")
        (1..parts.length).map do |i|
          parts.last(i).map(&:underscore).join("_")
        end
      end

      private

      def colon_delimited_names
        name_parts = name.split("::")
        [qualified_name] + name_parts.each_index.map do |index|
          name_parts.drop(index).join("::").freeze
        end
      end
    end
  end
end
