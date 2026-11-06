# frozen_string_literal: true

using ActiveModule::ModuleRefinement

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

  describe "ModuleRefinement#underscored_names" do
    it "returns demodulized name for flat module" do
      names = EnumTestModules::StatusA.underscored_names
      expect(names).to eq(
        %w[status_a enum_test_modules_status_a]
      )
    end

    it "returns all nesting levels for nested module" do
      names = EnumTestModules::Nested::StatusA
              .underscored_names
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
    def with_rails_logger
      logger = instance_spy(Logger)
      rails = Module.new
      allow(rails).to receive(:logger).and_return(logger)
      stub_const("Rails", rails)
      yield logger
    end

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

    def define_unambiguous
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::StatusA,
                    EnumTestModules::StatusB
                  ]
        active_module_enum :status, suffix: true
      end
    end

    def expected_prefixed_warning
      "WARNING: `status_tino` is ambiguous. " \
        "Use `status_ambiguous_modules_tino`, " \
        "`status_banana_tino`, " \
        "`status_ambiguous_modules_banana_tino` for " \
        "unambiguous access. " \
        "Pass on_ambiguous: :silence " \
        "to suppress this warning."
    end

    it "warns when name is ambiguous" do
      with_rails_logger do |logger|
        define_ambiguous
        expect(logger).to have_received(:warn)
          .with(/WARNING: `tino` is ambiguous/)
      end
    end

    it "warns once with all prefixed unambiguous alternatives" do
      with_rails_logger do |logger|
        define_ambiguous(prefix: true)
        expect(logger).to have_received(:warn)
          .with(expected_prefixed_warning).once
      end
    end

    it "does not warn when module names are unambiguous" do
      with_rails_logger do |logger|
        define_unambiguous
        expect(logger).not_to have_received(:warn)
      end
    end

    it "does not warn when on_ambiguous: :silence" do
      with_rails_logger do |logger|
        define_ambiguous(on_ambiguous: :silence)
        expect(logger).not_to have_received(:warn)
      end
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
