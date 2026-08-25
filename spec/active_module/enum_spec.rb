# frozen_string_literal: true

module EnumTestModules
  module StatusA; end
  module StatusB; end

  module Nested
    module StatusA; end
    module StatusB; end
  end
end

module AmbiguousModules
  module Tino; end

  module Banana
    module Tino; end
  end

  module Lime
    module Tino; end
  end
end

module ActiveRecordMethodNameCollision
  module Save; end
  module Valid; end
  module Reload; end
  module Count; end
  module All; end
end

module CoreMethodNameCollision
  module Hash; end
  module Class; end
  module ObjectId; end
end

RSpec.describe ActiveModule::Enum do
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
        t.string :kind
      end
    end
    ActiveModule.register!
  end

  describe "with non active_module attribute" do
    it "raises ArgumentError" do
      expect do
        Class.new(ActiveRecord::Base) do
          self.table_name = "enum_test_objects"
          active_module_enum :nonexistent
        end
      end.to raise_error(
        ArgumentError,
        /not an active_module attribute/
      )
    end
  end

  describe "with prefix: true" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::StatusA,
                    EnumTestModules::StatusB
                  ]
        active_module_enum :status, prefix: true
      end
    end

    it "returns true for prefixed matching module" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_status_a?).to be true
    end

    it "returns false for prefixed non-matching module" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_status_b?).to be false
    end

    it "sets via prefixed bang method" do
      obj = klass.create!(
        status: EnumTestModules::StatusA
      )
      obj.status_status_b!
      expect(obj.reload.status)
        .to eq EnumTestModules::StatusB
    end

    it "filters by prefixed with_ scope" do
      klass.create!(status: EnumTestModules::StatusA)
      expect(klass.with_status_status_a.count).to eq 1
    end

    it "filters by prefixed class-level query method" do
      klass.create!(status: EnumTestModules::StatusA)
      expect(klass.status_status_a.count).to eq 1
    end
  end

  describe "with prefix: true and nested modules" do
    let(:klass) do
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
        active_module_enum :status, prefix: true
      end
    end

    it "resolves ambiguous prefixed demodulized to flat",
       :aggregate_failures do
      flat = klass.new(
        status: EnumTestModules::StatusB
      )
      nested = klass.new(
        status: EnumTestModules::Nested::StatusB
      )
      expect(flat.status_status_b?).to be true
      expect(nested.status_status_b?).to be false
      expect(nested.status_nested_status_b?).to be true
    end

    it "prefixes full underscored name" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusB
      )
      expect(obj.status_nested_status_b?).to be true
    end

    it "returns false for non-matching prefixed name" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusB
      )
      expect(obj.status_status_a?).to be false
    end

    it "sets nested module via prefixed bang" do
      obj = klass.create!(
        status: EnumTestModules::StatusA
      )
      obj.status_nested_status_b!
      expect(obj.reload.status)
        .to eq EnumTestModules::Nested::StatusB
    end

    it "filters ambiguous prefixed scope by flat",
       :aggregate_failures do
      flat = klass.create!(
        status: EnumTestModules::StatusA
      )
      klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      expect(klass.with_status_status_a.count).to eq 1
      expect(klass.with_status_status_a.first).to eq flat
    end

    it "filters by prefixed full underscored scope" do
      klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      expect(
        klass.with_status_nested_status_a.count
      ).to eq 1
    end
  end

  describe "with suffix: true" do
    let(:klass) do
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

    it "returns true for suffixed matching module" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_a_status?).to be true
    end

    it "returns false for suffixed non-matching module" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_b_status?).to be false
    end

    it "sets via suffixed bang method" do
      obj = klass.create!(
        status: EnumTestModules::StatusA
      )
      obj.status_b_status!
      expect(obj.reload.status)
        .to eq EnumTestModules::StatusB
    end

    it "filters by suffixed with_ scope" do
      klass.create!(status: EnumTestModules::StatusA)
      expect(klass.with_status_a_status.count).to eq 1
    end

    it "filters by suffixed class-level query method" do
      klass.create!(status: EnumTestModules::StatusA)
      expect(klass.status_a_status.count).to eq 1
    end
  end

  describe "with suffix: true and nested modules" do
    let(:klass) do
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
        active_module_enum :status, suffix: true
      end
    end

    it "resolves ambiguous suffixed demodulized to flat",
       :aggregate_failures do
      flat = klass.new(
        status: EnumTestModules::StatusB
      )
      nested = klass.new(
        status: EnumTestModules::Nested::StatusB
      )
      expect(flat.status_b_status?).to be true
      expect(nested.status_b_status?).to be false
      expect(nested.nested_status_b_status?).to be true
    end

    it "suffixes full underscored name" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusB
      )
      expect(obj.nested_status_b_status?).to be true
    end

    it "returns false for non-matching suffixed name" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusB
      )
      expect(obj.status_a_status?).to be false
    end

    it "sets nested module via suffixed bang" do
      obj = klass.create!(
        status: EnumTestModules::StatusA
      )
      obj.nested_status_b_status!
      expect(obj.reload.status)
        .to eq EnumTestModules::Nested::StatusB
    end

    it "filters ambiguous suffixed scope by flat",
       :aggregate_failures do
      flat = klass.create!(
        status: EnumTestModules::StatusA
      )
      klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      expect(klass.with_status_a_status.count).to eq 1
      expect(klass.with_status_a_status.first).to eq flat
    end

    it "filters by suffixed full underscored scope" do
      klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      expect(
        klass.with_nested_status_a_status.count
      ).to eq 1
    end
  end

  describe "with custom prefix string" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::StatusA,
                    EnumTestModules::StatusB
                  ]
        active_module_enum :status, prefix: "my_status"
      end
    end

    it "returns true for custom prefixed matching module" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.my_status_status_a?).to be true
    end

    it "returns false for custom prefixed non-matching" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.my_status_status_b?).to be false
    end

    it "filters by custom prefixed scope" do
      klass.create!(status: EnumTestModules::StatusA)
      expect(
        klass.with_my_status_status_a.count
      ).to eq 1
    end

    it "filters by custom prefixed class-level query" do
      klass.create!(status: EnumTestModules::StatusA)
      expect(klass.my_status_status_a.count).to eq 1
    end
  end

  describe "with custom prefix string and nested modules" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::Nested::StatusA,
                    EnumTestModules::Nested::StatusB
                  ]
        active_module_enum :status, prefix: "my_status"
      end
    end

    it "prefixes demodulized name with custom string" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusA
      )
      expect(obj.my_status_status_a?).to be true
    end

    it "prefixes full underscored name with custom string" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusA
      )
      expect(obj.my_status_nested_status_a?).to be true
    end

    it "filters by custom prefixed demodulized scope" do
      klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      expect(
        klass.with_my_status_status_a.count
      ).to eq 1
    end

    it "filters by custom prefixed full underscored scope" do
      klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      expect(
        klass.with_my_status_nested_status_a.count
      ).to eq 1
    end
  end

  describe "with custom suffix string" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::StatusA,
                    EnumTestModules::StatusB
                  ]
        active_module_enum :status, suffix: "my_suffix"
      end
    end

    it "returns true for custom suffixed matching module" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_a_my_suffix?).to be true
    end

    it "returns false for custom suffixed non-matching" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_b_my_suffix?).to be false
    end

    it "filters by custom suffixed scope" do
      klass.create!(status: EnumTestModules::StatusA)
      expect(
        klass.with_status_a_my_suffix.count
      ).to eq 1
    end

    it "filters by custom suffixed class-level query" do
      klass.create!(status: EnumTestModules::StatusA)
      expect(klass.status_a_my_suffix.count).to eq 1
    end
  end

  describe "with custom suffix string and nested modules" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    EnumTestModules::Nested::StatusA,
                    EnumTestModules::Nested::StatusB
                  ]
        active_module_enum :status, suffix: "my_suffix"
      end
    end

    it "suffixes demodulized name with custom string" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusA
      )
      expect(obj.status_a_my_suffix?).to be true
    end

    it "suffixes full underscored name with custom string" do
      obj = klass.new(
        status: EnumTestModules::Nested::StatusA
      )
      expect(obj.nested_status_a_my_suffix?).to be true
    end

    it "filters by custom suffixed demodulized scope" do
      klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      expect(
        klass.with_status_a_my_suffix.count
      ).to eq 1
    end

    it "filters by custom suffixed full underscored scope" do
      klass.create!(
        status: EnumTestModules::Nested::StatusA
      )
      expect(
        klass.with_nested_status_a_my_suffix.count
      ).to eq 1
    end
  end

  describe "without overriding core Object methods" do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
        attribute :status,
                  :active_module,
                  possible_modules: [
                    CoreMethodNameCollision::Hash,
                    CoreMethodNameCollision::Class,
                    CoreMethodNameCollision::ObjectId
                  ]
        active_module_enum :status
      end
    end

    let(:plain_klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "enum_test_objects"
      end
    end

    it "keeps #object_id on instances intact",
       :aggregate_failures do
      obj = klass.new(status: CoreMethodNameCollision::Hash)
      expect(obj.method(:object_id).unbind)
        .to eq(plain_klass.instance_method(:object_id))
      expect(obj.object_id).to eq(obj.__id__)
    end

    it "keeps #hash on instances intact",
       :aggregate_failures do
      obj = klass.new(status: CoreMethodNameCollision::Hash)
      expect(obj.method(:hash).unbind)
        .to eq(plain_klass.instance_method(:hash))
      expect(obj.hash).to be_an(Integer)
    end

    it "keeps #class on instances intact",
       :aggregate_failures do
      obj = klass.new(status: CoreMethodNameCollision::Hash)
      expect(obj.method(:class).unbind)
        .to eq(plain_klass.instance_method(:class))
      expect(obj.class).to eq klass
    end

    it "keeps #object_id on the class intact" do
      expect(klass.method(:object_id).unbind)
        .to eq(plain_klass.method(:object_id).unbind)
    end

    it "keeps #hash on the class intact",
       :aggregate_failures do
      expect(klass.method(:hash).unbind)
        .to eq(plain_klass.method(:hash).unbind)
      expect(klass.hash).to be_an(Integer)
    end

    it "keeps #class on the class intact",
       :aggregate_failures do
      expect(klass.method(:class).unbind)
        .to eq(plain_klass.method(:class).unbind)
      expect(klass.class).to eq Class
    end

    it "still defines collision-safe enum methods",
       :aggregate_failures do
      obj = klass.create!(status: CoreMethodNameCollision::Hash)
      expect(obj.hash?).to be true
      expect(obj.class?).to be false
      expect(obj.object_id?).to be false
      expect(klass.with_hash.count).to eq 1
      expect(klass.statuses.keys)
        .to include(CoreMethodNameCollision::Hash)
    end

    it "sets value via collision-safe bang method" do
      obj = klass.create!(
        status: CoreMethodNameCollision::ObjectId
      )
      obj.class!
      expect(obj.reload.status)
        .to eq CoreMethodNameCollision::Class
    end

    it "answers respond_to? for generated names",
       :aggregate_failures do
      obj = klass.new(status: CoreMethodNameCollision::Hash)
      expect(obj.respond_to?(:hash?)).to be true
      expect(obj.respond_to?(:hash!)).to be true
      expect(klass.respond_to?(:with_hash)).to be true
      expect(klass.respond_to?(:statuses)).to be true
    end
  end

  describe "still defines methods not already present" do
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

    it "generates methods when class_eval block is empty" do
      obj = klass.new(status: EnumTestModules::StatusA)
      expect(obj.status_a?).to be true
    end
  end
end
