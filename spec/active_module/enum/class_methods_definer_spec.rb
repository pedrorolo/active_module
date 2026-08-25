# frozen_string_literal: true

RSpec.describe ActiveModule::Enum::ClassMethodsDefiner do
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

  describe "scopes" do
    before do
      klass.create!(status: EnumTestModules::StatusA)
      klass.create!(status: EnumTestModules::StatusB)
    end

    it "filters by with_ scope" do
      expect(klass.with_status_a.count).to eq 1
    end

    it "filters by class-level query method" do
      expect(klass.status_a.count).to eq 1
    end

    it "filters other value by with_ scope" do
      expect(klass.with_status_b.count).to eq 1
    end

    it "filters other value by class-level query" do
      expect(klass.status_b.count).to eq 1
    end
  end

  describe "nested scopes" do
    before do
      nested_klass.create!(
        status: EnumTestModules::StatusA
      )
      nested_klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
    end

    it "filters demodulized scope" do
      expect(nested_klass.with_status_a.count).to eq 1
    end

    it "filters full underscored scope" do
      expect(
        nested_klass.with_nested_status_a.count
      ).to eq 1
    end
  end

  describe "nested scopes at every level",
           :aggregate_failures do
    before do
      nested_klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      nested_klass.create!(
        status: EnumTestModules::StatusA
      )
    end

    it "generates with_ scopes at every nesting" do
      expect(
        nested_klass.with_nested_status_a.count
      ).to eq 1
      expect(nested_klass.with_status_b.count).to eq 0
      expect(
        nested_klass.with_nested_status_b.count
      ).to eq 0
    end

    it "generates class-level queries at every nesting" do
      expect(
        nested_klass.nested_status_a.count
      ).to eq 1
      expect(nested_klass.status_b.count).to eq 0
      expect(
        nested_klass.nested_status_b.count
      ).to eq 0
    end
  end

  describe "ambiguous scope resolves to flat module",
           :aggregate_failures do
    let!(:flat) do
      nested_klass.create!(
        status: EnumTestModules::StatusA
      )
    end

    before do
      nested_klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
    end

    it "with_ scope resolves to flat module" do
      expect(nested_klass.with_status_a.count).to eq 1
      expect(nested_klass.with_status_a.first).to eq flat
    end

    it "class-level query resolves to flat module" do
      expect(nested_klass.status_a.count).to eq 1
      expect(nested_klass.status_a.first).to eq flat
    end
  end

  describe "fields method" do
    let(:mapped_klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::StatusA,
                    EnumTestModules::StatusB
                  ],
                  mapping: {
                    EnumTestModules::StatusA => "m1"
                  }
        active_module_enum :status
      end
    end

    it "returns a hash of modules to fully qualified names" do
      expect(klass.statuses).to eq(
        EnumTestModules::StatusA =>
          "EnumTestModules::StatusA",
        EnumTestModules::StatusB =>
          "EnumTestModules::StatusB"
      )
    end

    it "takes custom mappings into account" do
      expect(mapped_klass.statuses).to eq(
        EnumTestModules::StatusA => "m1",
        EnumTestModules::StatusB =>
          "EnumTestModules::StatusB"
      )
    end

    it "returns keys as modules" do
      expect(klass.statuses.keys)
        .to all(be_a(Module))
    end

    it "returns values as strings" do
      expect(klass.statuses.values)
        .to all(be_a(String))
    end
  end

  describe "fields method with nested modules" do
    it "maps modules to fully qualified names" do
      expect(nested_klass.statuses).to eq(
        EnumTestModules::StatusA =>
          "EnumTestModules::StatusA",
        EnumTestModules::StatusB =>
          "EnumTestModules::StatusB",
        EnumTestModules::Nested::StatusA =>
          "EnumTestModules::Nested::StatusA",
        EnumTestModules::Nested::StatusB =>
          "EnumTestModules::Nested::StatusB"
      )
    end

    it "maps correct module to its qualified name",
       :aggregate_failures do
      fields = nested_klass.statuses
      expect(fields[EnumTestModules::StatusA])
        .to eq "EnumTestModules::StatusA"
      expect(fields[EnumTestModules::Nested::StatusA])
        .to eq "EnumTestModules::Nested::StatusA"
    end
  end

  describe "does not overwrite existing class methods" do
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

    it "skips class-level query already defined" do
      klass = build_klass do
        def self.status_a
          "custom_class"
        end
      end
      expect(klass.status_a).to eq "custom_class"
    end

    it "skips with_ scope already defined" do
      klass = build_klass do
        def self.with_status_a
          "custom_scope"
        end
      end
      expect(klass.with_status_a).to eq "custom_scope"
    end

    it "skips fields method already defined" do
      klass = build_klass do
        def self.statuses
          { custom: true }
        end
      end
      expect(klass.statuses).to eq(custom: true)
    end
  end

  describe "with scope: false" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::StatusA,
                    EnumTestModules::StatusB
                  ]
        active_module_enum :status, scope: false
      end
    end

    it "does not generate with_ scopes" do
      expect(klass).not_to respond_to(:with_status_a)
    end

    it "does not generate other with_ scopes" do
      expect(klass).not_to respond_to(:with_status_b)
    end

    it "still generates class-level query methods" do
      klass.create!(status: EnumTestModules::StatusA)
      expect(klass.status_a.count).to eq 1
    end
  end

  describe "with scope: false and nested modules" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::StatusA,
                    EnumTestModules::Nested::StatusA
                  ]
        active_module_enum :status, scope: false
      end
    end

    it "does not generate demodulized with_ scopes" do
      expect(klass).not_to respond_to(:with_status_a)
    end

    it "does not generate full underscored with_ scopes" do
      expect(klass).not_to respond_to(:with_nested_status_a)
    end

    it "resolves ambiguous query to flat module",
       :aggregate_failures do
      flat = klass.create!(
        status: EnumTestModules::StatusA
      )
      klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      expect(klass.status_a.count).to eq 1
      expect(klass.status_a.first).to eq flat
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

    it "still generates with_ scopes" do
      klass.create!(status: EnumTestModules::StatusA)
      expect(klass.with_status_a.count).to eq 1
    end

    it "does not generate class-level query methods" do
      expect(klass).not_to respond_to(:status_a)
    end
  end

  describe "with both false" do
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
                           scope: false,
                           instance_methods: false
      end
    end

    it "does not generate with_ scopes" do
      expect(klass).not_to respond_to(:with_status_a)
    end

    it "does not generate class-level query methods" do
      expect(klass).not_to respond_to(:status_a)
    end
  end

  describe "does not overwrite AR built-in methods" do
    def build_ar_klass(mod)
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [mod]
        active_module_enum :status
      end
    end

    it "does not overwrite count but defines with_count",
       :aggregate_failures do
      klass = build_ar_klass(
        ActiveRecordMethodNameCollision::Count
      )
      expect(klass.count).to be_a(Integer)
      expect(klass).to respond_to(:with_count)
    end

    it "does not overwrite all but defines with_all",
       :aggregate_failures do
      klass = build_ar_klass(
        ActiveRecordMethodNameCollision::All
      )
      expect(klass.all).to be_a(ActiveRecord::Relation)
      expect(klass).to respond_to(:with_all)
    end

    it "does not overwrite save! but defines save?",
       :aggregate_failures do
      klass = build_ar_klass(
        ActiveRecordMethodNameCollision::Save
      )
      obj = klass.new(
        status: ActiveRecordMethodNameCollision::Save
      )
      expect(obj.save?).to be true
      obj.save
      expect(obj).to be_persisted
    end

    it "does not overwrite valid? but defines valid!",
       :aggregate_failures do
      klass = build_ar_klass(
        ActiveRecordMethodNameCollision::Valid
      )
      obj = klass.new(
        status: ActiveRecordMethodNameCollision::Valid
      )
      expect(obj).to be_valid
      expect(obj).to respond_to(:valid!)
    end

    it "does not overwrite reload but defines reload?",
       :aggregate_failures do
      klass = build_ar_klass(
        ActiveRecordMethodNameCollision::Reload
      )
      saved = klass.create!(
        status:
          ActiveRecordMethodNameCollision::Reload
      )
      expect(saved.reload?).to be true
      expect(saved.reload.reload?).to be true
    end
  end
end
