# frozen_string_literal: true

module ActiveModule
  module Enum
    module ClassMethodsDefiner
      def define_class_query(attribute_name, mod,
                             value_name, opts,
                             existing)
        name = enum_method_name(value_name, opts)
        return if existing[:singleton]
                  .include?(name.to_sym)

        define_singleton_method(name) do
          where(attribute_name => mod)
        end
      end

      def define_enum_scope(attribute_name, mod,
                            value_name, opts,
                            existing)
        name = enum_method_name(value_name, opts)
        scope_name = :"with_#{name}"
        return if existing[:singleton]
                  .include?(scope_name)

        define_singleton_method(scope_name) do
          where(attribute_name => mod)
        end
      end

      def define_fields_method(attribute_name, modules)
        fields = build_fields_map(modules)
        name = attribute_name.to_s.pluralize
        return if singleton_methods.include?(name.to_sym)

        define_singleton_method(name) { fields }
      end

      def build_fields_map(modules)
        modules.each_with_object({}) do |mod, h|
          h[mod] = mod.name
        end
      end
    end
  end
end
