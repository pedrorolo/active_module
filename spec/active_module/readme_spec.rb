# frozen_string_literal: true

module ReadmeModules
  module StrategyA; end
  module StrategyB; end

  module Nested
    module StrategyA; end
  end

  module Lime
    module Banana
      module Strawberry; end
    end
  end
end

module ReadmeComparison
  using ActiveModule::Comparison

  def self.compare_results(mod1, mod2)
    mod1 =~ mod2
  end
end

module ReadmeEnumComparison
  using ActiveModule::Comparison

  def self.match?(mod, value)
    mod =~ value
  end
end

RSpec.describe ActiveModule do # rubocop:disable RSpec/SpecFilePathFormat
  before do
    require "active_record"

    ActiveRecord::Migration.verbose = false
    ActiveRecord::Base.logger = Logger.new(nil)
    ActiveRecord::Base.establish_connection(adapter: "sqlite3",
                                            database: ":memory:")

    ActiveRecord::Base.connection.instance_eval do
      create_table :readme_objects do |t|
        t.string :strategy
        t.string :fruit
      end
    end

    described_class.register!
  end

  let(:klass) do
    modules = ReadmeModules
    Class.new(ActiveRecord::Base) do
      self.table_name = "readme_objects"
      attribute :strategy,
                :active_module,
                possible_modules: [
                  modules::StrategyA,
                  modules::StrategyB,
                  modules::Nested::StrategyA,
                  modules::Lime::Banana::Strawberry
                ]
    end
  end

  describe "TL;DR: assigning" do
    it "assigns with module literal" do
      object = klass.new
      object.strategy = ReadmeModules::StrategyA
      expect(object.strategy).to eq ReadmeModules::StrategyA
    end

    it "assigns with unqualified symbol" do
      object = klass.new
      object.strategy = :StrategyB
      expect(object.strategy).to eq ReadmeModules::StrategyB
    end

    it "assigns with unqualified string" do
      object = klass.new
      object.strategy = "StrategyB"
      expect(object.strategy).to eq ReadmeModules::StrategyB
    end

    it "assigns with underscored nested name" do
      object = klass.new
      object.strategy = :nested_strategy_a
      expect(object.strategy)
        .to eq ReadmeModules::Nested::StrategyA
    end

    it "assigns with fully underscored nested name" do
      object = klass.new
      object.strategy = :lime_banana_strawberry
      expect(object.strategy)
        .to eq ReadmeModules::Lime::Banana::Strawberry
    end
  end

  describe "TL;DR: querying" do
    before do
      klass.create!(strategy: ReadmeModules::StrategyA)
      klass.create!(
        strategy: ReadmeModules::Nested::StrategyA
      )
      klass.create!(
        strategy: ReadmeModules::Lime::Banana::Strawberry
      )
    end

    it "queries with module literal" do
      found = klass.find_by(
        strategy: ReadmeModules::Nested::StrategyA
      )
      expect(found.strategy)
        .to eq ReadmeModules::Nested::StrategyA
    end

    it "queries with unqualified symbol" do
      found = klass.find_by(strategy: :StrategyA)
      expect(found.strategy)
        .to eq ReadmeModules::StrategyA
    end

    it "queries with unqualified string" do
      found = klass.find_by(strategy: "StrategyA")
      expect(found.strategy)
        .to eq ReadmeModules::StrategyA
    end

    it "queries with underscored nested name" do
      found = klass.find_by(strategy: :nested_strategy_a)
      expect(found.strategy)
        .to eq ReadmeModules::Nested::StrategyA
    end

    it "queries with fully underscored nested name" do
      found = klass.find_by(strategy: :lime_banana_strawberry)
      expect(found.strategy)
        .to eq ReadmeModules::Lime::Banana::Strawberry
    end
  end

  describe "TL;DR: comparing" do
    it "compares with == using module literal" do
      object = klass.new(strategy: ReadmeModules::StrategyA)
      expect(object.strategy == ReadmeModules::StrategyA)
        .to be true
    end

    it "compares with =~ using unqualified symbol" do
      object = klass.new(strategy: ReadmeModules::StrategyB)
      result = ReadmeComparison.compare_results(
        object.strategy, :StrategyB
      )
      expect(result).to be true
    end

    it "compares with =~ using unqualified string" do
      object = klass.new(strategy: ReadmeModules::StrategyB)
      result = ReadmeComparison.compare_results(
        object.strategy, "StrategyB"
      )
      expect(result).to be true
    end

    it "compares using Comparison.compare" do
      object = klass.new(strategy: ReadmeModules::StrategyB)
      result = ActiveModule::Comparison.compare(
        object.strategy, :StrategyB
      )
      expect(result).to be true
    end
  end

  describe "Comparison with underscored names" do
    it "compares with demodulized underscore symbol" do
      result = ReadmeEnumComparison.match?(
        ReadmeModules::Nested::StrategyA,
        :strategy_a
      )
      expect(result).to be true
    end

    it "compares with full underscored nested symbol" do
      result = ReadmeEnumComparison.match?(
        ReadmeModules::Nested::StrategyA,
        :nested_strategy_a
      )
      expect(result).to be true
    end

    it "compares with CamelCase unqualified symbol" do
      result = ReadmeEnumComparison.match?(
        ReadmeModules::Nested::StrategyA,
        :StrategyA
      )
      expect(result).to be true
    end

    it "compares with CamelCase unqualified string" do
      result = ReadmeEnumComparison.match?(
        ReadmeModules::Nested::StrategyA,
        "StrategyA"
      )
      expect(result).to be true
    end

    it "compares using Comparison.compare" do
      result = ActiveModule::Comparison.compare(
        ReadmeModules::Nested::StrategyA,
        :nested_strategy_a
      )
      expect(result).to be true
    end
  end

  describe "assigning with fully qualified strings" do
    it "assigns disambiguated nested module" do
      object = klass.new
      object.strategy = "Nested::StrategyA"
      expect(object.strategy)
        .to eq ReadmeModules::Nested::StrategyA
    end
  end

  describe "comparing with fully qualified string" do
    it "compares with =~ using fully qualified string" do
      object = klass.new(
        strategy: ReadmeModules::Nested::StrategyA
      )
      result = ReadmeComparison.compare_results(
        object.strategy, "Nested::StrategyA"
      )
      expect(result).to be true
    end
  end

  describe "enum: deep nesting (3 levels)" do
    let(:fruit_klass) do
      mods = ReadmeModules
      Class.new(ActiveRecord::Base) do
        self.table_name = "readme_objects"
        attribute :fruit,
                  :active_module,
                  possible_modules: [
                    mods::Lime::Banana::Strawberry
                  ]
        active_module_enum :fruit
      end
    end

    it "generates demodulized query method" do
      object = fruit_klass.new(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      expect(object.strawberry?).to be true
    end

    it "generates partial nesting query method" do
      object = fruit_klass.new(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      expect(object.banana_strawberry?).to be true
    end

    it "generates full nesting query method" do
      object = fruit_klass.new(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      expect(object.lime_banana_strawberry?).to be true
    end

    it "generates bang method for demodulized name" do
      object = fruit_klass.create!(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      object.strawberry!
      expect(object.reload.fruit)
        .to eq ReadmeModules::Lime::Banana::Strawberry
    end

    it "generates bang method for partial nesting" do
      object = fruit_klass.create!(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      object.banana_strawberry!
      expect(object.reload.fruit)
        .to eq ReadmeModules::Lime::Banana::Strawberry
    end

    it "generates bang method for full nesting" do
      object = fruit_klass.create!(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      object.lime_banana_strawberry!
      expect(object.reload.fruit)
        .to eq ReadmeModules::Lime::Banana::Strawberry
    end

    it "generates with_ scope for demodulized name" do
      fruit_klass.create!(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      expect(fruit_klass.with_strawberry.count).to eq 1
    end

    it "generates with_ scope for partial nesting" do
      fruit_klass.create!(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      expect(fruit_klass.with_banana_strawberry.count)
        .to eq 1
    end

    it "generates with_ scope for full nesting" do
      fruit_klass.create!(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      expect(fruit_klass.with_lime_banana_strawberry.count)
        .to eq 1
    end

    it "generates class-level query method" do
      fruit_klass.create!(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      expect(fruit_klass.strawberry.count).to eq 1
    end

    it "queries with underscored symbol" do
      fruit_klass.create!(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      found = fruit_klass.find_by(fruit: :strawberry)
      expect(found.fruit)
        .to eq ReadmeModules::Lime::Banana::Strawberry
    end

    it "queries with partial nesting symbol" do
      fruit_klass.create!(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      found = fruit_klass.find_by(
        fruit: :banana_strawberry
      )
      expect(found.fruit)
        .to eq ReadmeModules::Lime::Banana::Strawberry
    end

    it "queries with full nesting symbol" do
      fruit_klass.create!(
        fruit: ReadmeModules::Lime::Banana::Strawberry
      )
      found = fruit_klass.find_by(
        fruit: :lime_banana_strawberry
      )
      expect(found.fruit)
        .to eq ReadmeModules::Lime::Banana::Strawberry
    end
  end

  describe "enum: deep nesting comparison" do
    it "compares with Comparison using underscore" do
      result = ReadmeEnumComparison.match?(
        ReadmeModules::Lime::Banana::Strawberry,
        :banana_strawberry
      )
      expect(result).to be true
    end

    it "compares with Comparison using demodulized" do
      result = ReadmeEnumComparison.match?(
        ReadmeModules::Lime::Banana::Strawberry,
        :strawberry
      )
      expect(result).to be true
    end
  end

  describe "enum: on_ambiguous option" do
    let(:ambiguous_klass) do
      modules = ReadmeModules
      Class.new(ActiveRecord::Base) do
        self.table_name = "readme_objects"
        attribute :fruit,
                  :active_module,
                  possible_modules: [
                    modules::StrategyA,
                    modules::Nested::StrategyA
                  ]
        active_module_enum :fruit,
                           on_ambiguous: :silence
      end
    end

    it "does not warn when on_ambiguous: :silence" do
      expect { ambiguous_klass }
        .not_to output.to_stderr
    end

    it "generates methods when on_ambiguous: :silence" do
      object = ambiguous_klass.new(
        fruit: ReadmeModules::Nested::StrategyA
      )
      expect(object.nested_strategy_a?).to be true
    end
  end
end
