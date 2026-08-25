# frozen_string_literal: true

module ActiveModule
  module Enum
    module InstanceMethodsDefiner
      def define_instance_methods(attribute_name, mod,
                                  value_name, opts,
                                  existing)
        name = enum_method_name(value_name, opts)
        define_if_new(
          existing[:instance], :"#{name}?"
        ) do
          public_send(attribute_name) == mod
        end
        define_if_new(
          existing[:instance], :"#{name}!"
        ) do
          public_send("#{attribute_name}=", mod)
          save!
        end
      end
    end
  end
end
