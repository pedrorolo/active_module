# frozen_string_literal: true

RSpec.describe ActiveModule::Enum::InstanceMethodsDefiner do
  before do
    require "active_record"
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Base.logger = Logger.new(nil)
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3", database: ":memory:"
    )
    ActiveRecord::Base.connection.instance_eval do
      create_table :enum_test_objects do |t|
        t.string :status
      end
    end
    ActiveModule.register!
  end

  let(:klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "enum_test_objects"
      attribute :status,
                :active_module,
                possible_modules: [
                  EnumTestModules::StatusA,
                  EnumTestModules::StatusB
                ]
      active_module_enum :status
    end
  end

  let(:nested_klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "enum_test_objects"
      attribute :status,
                :active_module,
                possible_modules: [
                  EnumTestModules::StatusA,
                  EnumTestModules::StatusB,
                  EnumTestModules::Nested::StatusA,
                  EnumTestModules::Nested::StatusB
                ]
      active_module_enum :status
    end
  end

  describe "query methods" do
    it "returns true for matching module" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_a?).to be true
    end

    it "returns false for non-matching module" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_b?).to be false
    end

    it "resolves ambiguous to flat module",
       :aggregate_failures do
      flat = nested_klass.new(
        status: EnumTestModules::StatusB
      )
      nested = nested_klass.new(
        status: EnumTestModules::Nested::StatusB
      )
      expect(flat.status_b?).to be true
      expect(nested.status_b?).to be false
      expect(nested.nested_status_b?).to be true
    end

    it "matches full underscored name" do
      obj = nested_klass.new(
        status: EnumTestModules::Nested::StatusB
      )
      expect(obj.nested_status_b?).to be true
    end

    it "returns false for unmatched nested module" do
      obj = nested_klass.new(
        status: EnumTestModules::Nested::StatusB
      )
      expect(obj.nested_status_a?).to be false
    end
  end

  describe "bang methods" do
    it "sets and saves the module value" do
      obj = klass.create!(
        status: EnumTestModules::StatusA
      )
      obj.status_b!
      expect(obj.reload.status)
        .to eq EnumTestModules::StatusB
    end

    it "sets nested module via bang method" do
      obj = nested_klass.create!(
        status: EnumTestModules::StatusA
      )
      obj.nested_status_b!
      expect(obj.reload.status)
        .to eq EnumTestModules::Nested::StatusB
    end

    it "resolves ambiguous bang to flat module" do
      obj = nested_klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      obj.status_b!
      expect(obj.reload.status)
        .to eq EnumTestModules::StatusB
    end
  end

  describe "nested instance methods at every level" do
    let(:flat_klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::StatusA,
                    EnumTestModules::StatusB
                  ]
        active_module_enum :status
      end
    end

    it "generates ? methods at every nesting level",
       :aggregate_failures do
      flat = nested_klass.new(
        status: EnumTestModules::StatusA
      )
      nested = nested_klass.new(
        status: EnumTestModules::Nested::StatusA
      )
      expect(flat.status_a?).to be true
      expect(nested.status_a?).to be false
      expect(nested.nested_status_a?).to be true
    end

    it "generates ! methods for nested modules" do
      obj = nested_klass.create!(
        status: EnumTestModules::StatusA
      )
      obj.nested_status_b!
      expect(obj.reload.status)
        .to eq EnumTestModules::Nested::StatusB
    end

    it "generates ! methods for flat modules" do
      obj = flat_klass.create!(
        status: EnumTestModules::StatusA
      )
      obj.status_b!
      expect(obj.reload.status)
        .to eq EnumTestModules::StatusB
    end
  end

  describe "with instance_methods: false" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::StatusA,
                    EnumTestModules::StatusB
                  ]
        active_module_enum :status,
                           instance_methods: false
      end
    end

    it "does not generate query instance methods" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj).not_to respond_to(:status_a?)
    end

    it "does not generate bang instance methods" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj).not_to respond_to(:status_a!)
    end
  end

  describe "with instance_methods: false and nested" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::Nested::StatusA,
                    EnumTestModules::Nested::StatusB
                  ]
        active_module_enum :status,
                           instance_methods: false
      end
    end

    it "does not generate demodulized query methods" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusA
      )
      expect(obj).not_to respond_to(:status_a?)
    end

    it "does not generate demodulized bang methods" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusA
      )
      expect(obj).not_to respond_to(:status_a!)
    end

    it "does not generate full underscored query" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusA
      )
      expect(obj).not_to respond_to(:nested_status_a?)
    end

    it "does not generate full underscored bang" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusA
      )
      expect(obj).not_to respond_to(:nested_status_a!)
    end
  end

  describe "does not overwrite existing instance methods" do
    def build_klass(&block)
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::StatusA,
                    EnumTestModules::StatusB
                  ]
        class_eval(&block)
        active_module_enum :status
      end
    end

    it "skips instance query method already defined" do
      klass = build_klass do
        def status_a?
          "custom"
        end
      end
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_a?).to eq "custom"
    end

    it "skips instance bang method already defined" do
      klass = build_klass do
        def status_a!
          "custom_bang"
        end
      end
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_a!).to eq "custom_bang"
    end
  end
end
