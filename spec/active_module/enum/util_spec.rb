# frozen_string_literal: true

RSpec.describe ActiveModule::Enum::Util do
  let(:klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "enum_test_objects"
      attribute :status,
                :active_module,
                possible_modules: [EnumTestModules::StatusA,
                                   EnumTestModules::StatusB]
      active_module_enum :status, on_ambiguous: :silence
    end
  end

  describe "#underscored_names" do
    it "returns demodulized name for flat module" do
      names = klass.send(
        :underscored_names,
        EnumTestModules::StatusA
      )
      expect(names).to eq(
        %w[status_a enum_test_modules_status_a]
      )
    end

    it "returns all nesting levels for nested module" do
      names = klass.send(
        :underscored_names,
        EnumTestModules::Nested::StatusA
      )
      expect(names).to eq(
        %w[status_a nested_status_a
           enum_test_modules_nested_status_a]
      )
    end
  end

  describe "#determine_prefix" do
    it "returns nil when no prefix" do
      result = klass.send(
        :determine_prefix, :status, nil, nil
      )
      expect(result).to be_nil
    end

    it "returns attribute name when prefix: true" do
      result = klass.send(
        :determine_prefix, :status, true, nil
      )
      expect(result).to eq("status")
    end

    it "returns custom string when prefix is a string" do
      result = klass.send(
        :determine_prefix, :status, "custom", nil
      )
      expect(result).to eq("custom")
    end
  end

  describe "#determine_suffix" do
    it "returns nil when no suffix" do
      result = klass.send(
        :determine_suffix, :status, nil, nil
      )
      expect(result).to be_nil
    end

    it "returns attribute name when suffix: true" do
      result = klass.send(
        :determine_suffix, :status, nil, true
      )
      expect(result).to eq("status")
    end

    it "returns custom string when suffix is a string" do
      result = klass.send(
        :determine_suffix, :status, nil, "custom"
      )
      expect(result).to eq("custom")
    end
  end

  describe "#enum_method_name" do
    it "joins parts with underscore" do
      result = klass.send(
        :enum_method_name, "status_a",
        prefix: nil, suffix: nil
      )
      expect(result).to eq("status_a")
    end

    it "includes prefix when present" do
      result = klass.send(
        :enum_method_name, "status_a",
        prefix: "my", suffix: nil
      )
      expect(result).to eq("my_status_a")
    end

    it "includes suffix when present" do
      result = klass.send(
        :enum_method_name, "status_a",
        prefix: nil, suffix: "field"
      )
      expect(result).to eq("status_a_field")
    end
  end

  describe "#warn_if_ambiguous" do
    def define_ambiguous(**opts)
      modules = [
        AmbiguousModules::Tino,
        AmbiguousModules::Banana::Tino
      ]
      options = opts
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: modules
        active_module_enum :status, **options
      end
    end

    it "warns when name is ambiguous" do
      expect { define_ambiguous }
        .to output(/WARNING: `tino` is ambiguous/)
        .to_stderr
    end

    it "does not warn when on_ambiguous: :silence" do
      expect { define_ambiguous(on_ambiguous: :silence) }
        .not_to output.to_stderr
    end
  end

  describe "#build_name_maps" do
    let(:ambiguous_maps) do
      mods = [
        AmbiguousModules::Tino,
        AmbiguousModules::Banana::Tino,
        AmbiguousModules::Lime::Tino
      ].sort_by { |m| -m.name.count("::") }
      klass.send(:build_name_maps, mods)
    end

    let(:nested_maps) do
      mods = [
        EnumTestModules::StatusA,
        EnumTestModules::Nested::StatusA
      ].sort_by { |m| -m.name.count("::") }
      klass.send(:build_name_maps, mods)
    end

    it "identifies ambiguous names" do
      expect(ambiguous_maps[:ambiguity]["tino"].size)
        .to eq 3
    end

    it "identifies unique names for flat module" do
      expect(
        nested_maps[:unique][EnumTestModules::StatusA]
      ).to eq(["enum_test_modules_status_a"])
    end

    it "identifies unique names for nested module" do
      expect(
        nested_maps[:unique][
          EnumTestModules::Nested::StatusA
        ]
      ).to include(
        "nested_status_a",
        "enum_test_modules_nested_status_a"
      )
    end
  end
end
