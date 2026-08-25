# frozen_string_literal: true

module ActiveModule
  module Enum
    using ModuleRefinement
    include Util
    include InstanceMethodsDefiner
    include ClassMethodsDefiner

    def active_module_enum(attribute_name,
                           prefix: nil,
                           suffix: nil,
                           scope: true,
                           **options)
      type = attribute_types[attribute_name.to_s]
      unless type.is_a?(ActiveModule::Base)
        raise ArgumentError,
              "#{attribute_name} is not " \
              "an active_module attribute"
      end
      opts = build_enum_opts(
        attribute_name, prefix, suffix,
        scope, options
      )
      mods = type.possible_modules
      define_enum_methods(attribute_name, mods, opts)
      define_fields_method(attribute_name, mods)
    end

    private

    def build_enum_opts(attribute_name, prefix,
                        suffix, scope, options)
      {
        prefix: determine_prefix(
          attribute_name, prefix, suffix
        ),
        suffix: determine_suffix(
          attribute_name, prefix, suffix
        ),
        scope: scope,
        instance_methods: options.fetch(
          :instance_methods, true
        ),
        on_ambiguous: options.fetch(
          :on_ambiguous, :warn
        )
      }
    end

    def define_enum_methods(attribute_name, modules, opts)
      sorted = modules
               .sort_by { |m| -m.name.count("::") }
      maps = build_name_maps(sorted)
      existing = {
        instance: instance_methods,
        singleton: singleton_methods
      }
      sorted.each do |mod|
        generate_methods(
          attribute_name, mod, opts, maps, existing
        )
      end
    end

    def generate_methods(attribute_name, mod, opts,
                         maps, existing)
      mod.underscored_names.each do |value_name|
        warn_if_ambiguous(mod, value_name, opts, maps)
        if opts[:instance_methods]
          define_instance_methods(
            attribute_name, mod, value_name,
            opts, existing
          )
        end
        if opts[:instance_methods]
          define_class_query(
            attribute_name, mod, value_name,
            opts, existing
          )
        end
        next unless opts[:scope]

        define_enum_scope(
          attribute_name, mod, value_name,
          opts, existing
        )
      end
    end
  end
end
