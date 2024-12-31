# frozen_string_literal: true

require_relative "module_refinement"

# Indexes modules by symbols of their qualified and unqualified names.
module ActiveModule
  class Enum
    class ModulesIndex < ActiveModule::ModulesIndex
      using ActiveModule::Enum::ModuleRefinement

      protected

      # so that this is using the enum refinement
      def possible_names(module_instance)
        module_instance.possible_names
      end
    end
  end
end
