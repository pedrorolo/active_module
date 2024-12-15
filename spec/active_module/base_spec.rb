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

    # silence_warnings do
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Base.logger = Logger.new(nil)
    ActiveRecord::Base.establish_connection(adapter: "sqlite3",
                                            database: ":memory:")
    # end

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

  it "mass assignment works" do
    object = active_record_class.new(strategy: :MoreNesting)
    expect(object.strategy).to eq Nested::MyClass::MoreNesting
  end

  it "assignment works" do
    object = active_record_class.new
    object.strategy = :MoreNesting
    expect(object.strategy).to eq Nested::MyClass::MoreNesting
  end
end
