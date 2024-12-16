# frozen_string_literal: true

require "active_model"
require_relative "modules_index"

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
      @modules_index ||= ModulesIndex.new(@possible_modules)
    end
  end
end
