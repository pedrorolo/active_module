# frozen_string_literal: true

require "active_model"

module ActiveModule
  class Type < ActiveModel::Type::Value
    class InvalidModuleValue < StandardError
      def initialize(value, possible_modules)
        super(<<~ERROR_MESSAGE)
          "Invalid module value #{value.inspect}:#{" "}
           It must be one of:#{" "}
            #{possible_modules.inspect}
           or one of their demodulized names:
            #{possible_modules.map(&:name).map(&:demodulize).inspect}"
        ERROR_MESSAGE
      end
    end

    def initialize(possible_modules:)
      @possible_modules = possible_modules
      super()
    end

    def type
      :module
    end

    def serializable?(object)
      possible_module?(object)
    end

    def cast(object)
      return nil if object.nil?

      case object
      when ::String
        str_to_module(object)
      when ::Symbol
        str_to_module(object.to_s)
      when ::Module
        if possible_module?(object)
          object
        else
          raise_invalid_module_value_error(object)
        end
      else
        raise_invalid_module_value_error(object)
      end
    end

    def serialize(module_instance)
      cast(module_instance).name
    end

    def deserialize(str)
      str && cast(str)
    end

    private

    def str_to_module(str)
      if possible_full_module_names.include?(str)
        str.constantize
      elsif possible_demodulized_module_names.include?(str)
        @possible_modules.find { |module_instance| module_instance.name.demodulize == str }
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
      @possible_strings ||= possible_full_module_names + possible_demodulized_module_names
    end

    def possible_full_module_names
      @possible_full_module_names ||= Set.new(@possible_modules.map(&:name))
    end

    def possible_demodulized_module_names
      @possible_demodulized_module_names ||=
        Set.new(possible_full_module_names.map(&:demodulize))
    end
  end
end
