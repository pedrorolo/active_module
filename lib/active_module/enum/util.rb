# frozen_string_literal: true

module ActiveModule
  module Enum
    module Util
      def underscored_names(mod)
        parts = mod.name.split("::")
        (1..parts.length).map do |i|
          parts.last(i).map(&:underscore).join("_")
        end
      end

      def determine_prefix(attribute_name, prefix, suffix)
        if prefix.is_a?(String)
          prefix
        elsif prefix == true ||
              (prefix.nil? && suffix == true &&
               !prefix.nil?)
          prefix == true ? attribute_name.to_s : nil
        end
      end

      def determine_suffix(attribute_name, prefix, suffix)
        if suffix.is_a?(String)
          suffix
        elsif suffix == true && prefix != true
          attribute_name.to_s
        end
      end

      def enum_method_name(value_name, opts)
        [opts[:prefix], value_name, opts[:suffix]]
          .compact.join("_")
      end

      def define_if_new(existing, name, &block)
        return if existing.include?(name)

        define_method(name, &block)
      end

      def warn_if_ambiguous(mod, value_name, opts, maps)
        return unless maps[:ambiguity][value_name]&.size&.> 1
        return if opts[:on_ambiguous] == :silence

        name = enum_method_name(value_name, opts)
        alts = (maps[:unique][mod] || [])
               .map { |a| "`#{a}`" }
        warn("WARNING: `#{name}` is ambiguous. " \
             "Use #{alts.join(", ")} for " \
             "unambiguous access. " \
             "Pass on_ambiguous: :silence " \
             "to suppress this warning.")
      end

      def build_name_maps(modules)
        ambiguity = build_ambiguity_map(modules)
        unique = build_unique_names_map(
          modules, ambiguity
        )
        { ambiguity: ambiguity, unique: unique }
      end

      def build_ambiguity_map(modules)
        modules.each_with_object({}) do |mod, h|
          underscored_names(mod).each do |name|
            (h[name] ||= []) << mod
          end
        end
      end

      def build_unique_names_map(modules, ambiguity)
        modules.each_with_object({}) do |mod, h|
          underscored_names(mod).each do |name|
            next if ambiguity[name].size > 1

            (h[mod] ||= []) << name
          end
        end
      end
    end
  end
end
