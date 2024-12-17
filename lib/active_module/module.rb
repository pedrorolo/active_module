module ActiveModule
  class Module < SimpleDelegator
    using ModuleRefinement
    def new(module_instance)
      @module_instance = module_instance
    end

    def ==(other)
      @module_instance == other || possible_symbols.include?(other) || possible_names.include?(other)
    end

    def possible_names
      @possible_names ||= begin
        name_parts = name.split("::")
        [qualified_name].tap do |possible_names|
          loop do
            possible_names << name_parts.join("::").freeze
            name_parts = name_parts.drop(1)
            break if name_parts.empty?
          end
        end
      end
    end

    def qualified_name
      "::#{name}"
    end

    def possible_symbols
      @possible_symbols ||= Set.new(possible_names.map(&:to_sym))
    end
  end
end
