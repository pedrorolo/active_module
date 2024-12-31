# frozen_string_literal: true

module ActiveModule
  class Base < ActiveModel::Type::Value
    attr_reader :possible_modules, :mapping

    def initialize(possible_modules_or_mapping = [],
                   possible_modules: [],
                   mapping: {},
                   enum_compatibility: false)
      @enum_compatibility = enum_compatibility
      if possible_modules_or_mapping.is_a?(Array)
        @possible_modules =
          (possible_modules_or_mapping + possible_modules + mapping.keys).uniq
        @mapping = default_mapping.merge(mapping)
      else
        @possible_modules =
          (possible_modules_or_mapping.keys + possible_modules + mapping.keys)
          .uniq
        @mapping = default_mapping.merge(possible_modules_or_mapping)
                                  .merge(mapping)
      end
      super()
    end

    def ==(other)
      other.is_a?(Base) &&
        possible_modules == other.possible_modules &&
        mapping == other.mapping
    end

    def type
      :active_module
    end

    def serializable?(object)
      possible_module?(object)
    end

    def cast(value)
      case value
      when nil
        nil
      when ::Symbol
        sym_to_module(value)
      when ::Module
        if possible_module?(value)
          value
        else
          raise_invalid_module_value_error(value)
        end
      when ::String
        str_to_module(value)
      else
        raise_invalid_module_value_error(value)
      end
    end

    def serialize(module_instance)
      mapping[cast(module_instance)]
    end

    def deserialize(str)
      from_db[str]
    end

    private

    def sym_to_module(sym)
      modules_index[sym] ||
        raise_invalid_module_value_error(sym)
    end

    def str_to_module(str)
      modules_index[str.to_sym] ||
        raise_invalid_module_value_error(str)
    end

    def raise_invalid_module_value_error(str)
      raise InvalidModuleValue.new(
        str,
        possible_modules: @possible_modules,
        possible_symbols: modules_index.keys
      )
    end

    def possible_modules_set
      @possible_modules_set ||= Set.new(@possible_modules).freeze
    end

    def possible_module?(module_instance)
      possible_modules_set.include?(module_instance)
    end

    def modules_index
      @modules_index ||=
        (@enum_compatibility ? Enum::ModulesIndex : ModulesIndex)
        .new(@possible_modules)
    end

    def from_db
      @from_db ||= mapping.invert
    end

    def default_mapping
      @possible_modules.index_by(&:name).invert
    end
  end
end
