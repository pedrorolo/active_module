# frozen_string_literal: true

require "active_model"

module ActiveModule
  class Base < ActiveModel::Type::Value
    def initialize(possible_modules:)
      @possible_modules = possible_modules
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
      when ::Module
        if possible_module?(value)
          value
        else
          raise_invalid_module_value_error(value)
        end
      when ::String
        str_to_module(value)
      when ::Symbol
        str_to_module(value.to_s)
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

    def str_to_module(str)
      if possible_full_module_names.include?(global = globalize(str))
        global.constantize
      elsif (mod = possible_str_module_names_index[str])
        mod
      else
        raise_invalid_module_value_error(str)
      end
    end

    def raise_invalid_module_value_error(str)
      raise InvalidModuleValue.new(str, @possible_modules)
    end

    def possible_modules_set
      @possible_modules_set ||= Set.new(@possible_modules)
    end

    def possible_str?(str)
      @possible_strings.include?(str)
    end

    def possible_module?(module_instance)
      possible_modules_set.include?(module_instance)
    end

    def possible_strings
      @possible_strings ||= possible_str_module_names_index.keys
    end

    def possible_full_module_names
      Set.new(@possible_modules.map { |m| globalize(m.name).freeze })
    end

    def possible_str_module_names_index
      @possible_str_module_names_index ||=
        @possible_modules.flat_map do |module_instance|
          possible_module_names(module_instance).map do |name|
            [name.freeze, module_instance]
          end
        end.to_h
    end

    def possible_module_names(module_instance)
      name_parts = module_instance.name.split("::")
      [].tap do |possible_names|
        loop do
          possible_names << name_parts.join("::").freeze
          name_parts = name_parts.drop(1)
          break if name_parts.empty?
        end
      end
    end

    def globalize(module_name)
      module_name.start_with?("::") ? module_name : "::#{module_name}"
    end
  end
end
