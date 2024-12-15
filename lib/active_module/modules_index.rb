# frozen_string_literal: true

# Indexes modules by symbols of their qualified and unqualified names.
module ActiveModule
  class ModulesIndex
    def initialize(possible_modules)
      @possible_modules = possible_modules
    end

    def find(module_symbol)
      possible_sym_module_index[module_symbol]
    end

    def keys
      possible_sym_module_index.keys
    end

    private

    def possible_sym_module_index
      @possible_sym_module_index ||=
        @possible_modules.flat_map do |module_instance|
          possible_module_names(module_instance).map do |name|
            [name.to_sym, module_instance]
          end
        end.to_h.freeze
    end

    def possible_module_names(module_instance)
      name_parts = module_instance.name.split("::")
      [qualified_name(module_instance)].tap do |possible_names|
        loop do
          possible_names << name_parts.join("::").freeze
          name_parts = name_parts.drop(1)
          break if name_parts.empty?
        end
      end
    end

    def qualified_name(module_instance)
      "::#{module_instance.name}"
    end
  end
end
