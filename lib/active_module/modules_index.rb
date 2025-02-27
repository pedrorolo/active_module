# frozen_string_literal: true

# Indexes modules by symbols of their qualified and unqualified names.
module ActiveModule
  class ModulesIndex
    using ModuleRefinement

    delegate :[], to: :index
    delegate :keys, to: :index

    def initialize(modules)
      @modules = modules
    end

    protected

    def possible_names(module_instance)
      module_instance.possible_names
    end

    private

    def index
      @index ||=
        @modules.flat_map do |module_instance|
          possible_names(module_instance).map do |name|
            [name.to_sym, module_instance]
          end
        end.to_h.freeze
    end
  end
end
