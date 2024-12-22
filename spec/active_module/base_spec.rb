# frozen_string_literal: true

module StrategyA; end

module StrategyB; end

module Nested
  module StrategyA; end

  class MyClass
    class MoreNesting; end
  end
end

module RandomModule; end

RSpec.describe ActiveModule::Base do
  before do
    require "active_record"

    ActiveRecord::Migration.verbose = false
    ActiveRecord::Base.logger = Logger.new(nil)
    ActiveRecord::Base.establish_connection(adapter: "sqlite3",
                                            database: ":memory:")

    ActiveRecord::Base.connection.instance_eval do
      create_table :my_objects do |t|
        t.string :strategy
      end
    end
  end

  def active_record_class
    ActiveModule.register!
    Class.new(ActiveRecord::Base) do
      self.table_name = "my_objects"
      attribute :strategy,
                :active_module,
                possible_modules: [StrategyA,
                                   StrategyB,
                                   Nested::StrategyA,
                                   Nested::MyClass,
                                   Nested::MyClass::MoreNesting]
    end
  end

  def active_record_class_with_mapping
    ActiveModule.register!
    Class.new(ActiveRecord::Base) do
      self.table_name = "my_objects"
      attribute :strategy,
                :active_module,
                possible_modules: [StrategyA,
                                   StrategyB],
                mapping: { StrategyA => "s1" }
    end
  end

  it "is possible to assign using modules" do
    object = active_record_class.create!(strategy: StrategyA)
    expect(object.reload.strategy).to eq StrategyA
  end

  it "is possible to query using modules" do
    active_record_class.create!(strategy: StrategyA)
    expect(active_record_class.find_by(strategy: StrategyA).strategy)
      .to eq StrategyA
  end

  it "is possible to assign using classes" do
    object = active_record_class.create!(strategy: Nested::MyClass)
    expect(object.reload.strategy).to eq Nested::MyClass
  end

  it "is possible to query using classes" do
    active_record_class.create!(strategy: Nested::MyClass)
    expect(active_record_class.find_by(strategy: Nested::MyClass).strategy)
      .to eq Nested::MyClass
  end

  it "is possible to assign using strings" do
    object = active_record_class.create!(strategy: "StrategyB")
    expect(StrategyB).to eq object.reload.strategy
  end

  it "is possible to query using strings" do
    active_record_class.create!(strategy: "StrategyB")
    expect(StrategyB)
      .to eq active_record_class.find_by(strategy: "StrategyB").strategy
  end

  it "is possible to assign and query "\
  "using suffixes of the full module names" do
    active_record_class.create!(strategy: "MyClass::MoreNesting")
    expect(Nested::MyClass::MoreNesting)
      .to(
        eq active_record_class.find_by(strategy: "MyClass::MoreNesting")
                              .strategy
      )
  end

  it "is possible to assign and query "\
  "using nested suffixes of the full module names" do
    active_record_class.create!(strategy: "MoreNesting")
    expect(Nested::MyClass::MoreNesting)
      .to(
        eq active_record_class.find_by(strategy: "MoreNesting")
                              .strategy
      )
  end

  it "when creating with a module that is not in the "\
      "list of possible modules we get failures" do
    expect { active_record_class.create!(strategy: RandomModule) }
      .to raise_error(ActiveModule::InvalidModuleValue)
  end

  it "when creating with a string of an existing module that is not in the "\
      "list of possible modules we get failures" do
    expect { active_record_class.create!(strategy: "RandomModule") }
      .to raise_error(ActiveModule::InvalidModuleValue)
  end

  it "when creating with a string of a non-existing module"\
      "we get failures" do
        expect do
          active_record_class.create!(strategy: "WrongStringThatIsNotAModule")
        end.to raise_error(ActiveModule::InvalidModuleValue)
      end

  it "when querying with a module that is not in the "\
      "list of possible modules we get failures" do
    expect { active_record_class.where(strategy: RandomModule).load }
      .to raise_error(ActiveModule::InvalidModuleValue)
  end

  it "when querying with a string of an existing module that is not in the "\
  "list of possible modules we get failures" do
    expect { active_record_class.where(strategy: "RandomModule").load }
      .to raise_error(ActiveModule::InvalidModuleValue)
  end

  it "when querying with a string of a non-existing module"\
  "we get failures" do
    expect do
      active_record_class.where(strategy: "WrongStringThatIsNotAModule").load
    end.to raise_error(ActiveModule::InvalidModuleValue)
  end

  it "when querying with an object different than string symbol or module"\
  "we get failures" do
    expect do
      active_record_class.where(strategy: 1).load
    end.to raise_error(ActiveModule::InvalidModuleValue)
  end

  it "mass assignment works" do
    object = active_record_class.new(strategy: :MoreNesting)
    expect(object.strategy).to eq Nested::MyClass::MoreNesting
  end

  it "assignment works" do
    object = active_record_class.new
    object.strategy = :MoreNesting
    expect(object.strategy).to eq Nested::MyClass::MoreNesting
  end

  it "ActiveModule::Comparison#compare" do
    object = active_record_class.new
    object.strategy = :MoreNesting
    expect(ActiveModule::Comparison.compare(object.strategy, :MoreNesting))
      .to be true
  end

  it "supports qualified module names" do
    object = active_record_class.new
    object.strategy = ::Nested::MyClass::MoreNesting
    expect(object.strategy).to eq Nested::MyClass::MoreNesting
  end

  describe "#type" do
    it "returns :active_module" do
      expect(described_class.new(possible_modules: []).type)
        .to eq :active_module
    end
  end

  it "loads nil when what is in the database column is not a module" do
    object = active_record_class.create!
    ActiveRecord::Base.connection.execute(
      "UPDATE my_objects SET strategy = 'not_a_module' WHERE id = #{object.id}"
    )
    expect(object.reload.strategy).to be_nil
  end

  it "db mapping works" do
    model = active_record_class_with_mapping.create!(strategy: StrategyA)
    expect(model.reload.attributes_before_type_cast["strategy"]).to eq "s1"
  end

  describe "#initialize" do
    it "initializing with positional arguments "\
    "is the same as with possible_modules" do
      expect(described_class.new([StrategyA, StrategyB]))
        .to eq described_class.new(possible_modules: [StrategyA, StrategyB])
    end

    it "initializing with positional arguments is the same as with mapping" do
      expect(described_class.new({ StrategyA => "s1", StrategyB => "s2" }))
        .to eq described_class.new(mapping: { StrategyA => "s1",
                                              StrategyB => "s2" })
    end
  end
end
