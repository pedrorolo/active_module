# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"

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
        @modules
        .sort_by { |m| -m.name.count("::") }
        .flat_map do |module_instance|
          possible_names(module_instance).map do |name|
            [name.to_sym, module_instance]
          end
        end.to_h.with_indifferent_access.freeze
    end
  end
end
