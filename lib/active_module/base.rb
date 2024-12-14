# frozen_string_literal: true

require "active_model"

module ActiveModule
  class Base < ActiveModel::Type::Value
    def initialize(possible_modules:)
      @possible_modules = possible_modules.freeze
      super()
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
      cast(module_instance).name
    end

    def deserialize(str)
      str&.constantize
    end

    private

    def sym_to_module(sym)
      possible_sym_module_index[sym] ||
        raise_invalid_module_value_error(sym)
    end

    def str_to_module(str)
      possible_sym_module_index[str.to_sym] ||
        raise_invalid_module_value_error(str)
    end

    def raise_invalid_module_value_error(str)
      raise InvalidModuleValue.new(
        str,
        possible_modules: @possible_modules,
        possible_symbols: possible_sym_module_index.keys
      )
    end

    def possible_modules_set
      @possible_modules_set ||= Set.new(@possible_modules).freeze
    end

    def possible_module?(module_instance)
      possible_modules_set.include?(module_instance)
    end

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
      qualified_name = "::#{module_instance.name}"
      [qualified_name].tap do |possible_names|
        loop do
          possible_names << name_parts.join("::").freeze
          name_parts = name_parts.drop(1)
          break if name_parts.empty?
        end
      end
    end
  end
end
