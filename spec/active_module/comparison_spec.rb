# frozen_string_literal: true

module WithComparisonRefinement
  using ActiveModule::Comparison
  def self.compare_module_results(mod1, mod2)
    mod1 =~ mod2
  end
end

module ComparisonAmbiguous
  module StatusA; end

  module Nested
    module StatusA; end
  end
end

module NestedComparisonModules
  module Fruit; end

  module Banana
    module Strawberry; end
  end
end

RSpec.describe ActiveModule::Comparison do
  let(:my_class) do
    ActiveModule.register!

    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :module,
                :active_module,
                possible_modules: [String,
                                   Class,
                                   Module,
                                   Symbol,
                                   ActiveModule::Comparison,
                                   NestedComparisonModules::
                                     Banana::Strawberry]
    end
  end

  it "comparison works with symbols" do
    object = my_class.new(module: described_class)

    expect(WithComparisonRefinement
      .compare_module_results(
        object.module, :Comparison
      )).to be true
  end

  it "comparison works with Strings" do
    object = my_class.new(module: described_class)

    expect(WithComparisonRefinement
      .compare_module_results(
        object.module, "Comparison"
      )).to be true
  end

  it "comparison works with Modules" do
    mod = described_class
    object = my_class.new(module: mod)

    expect(WithComparisonRefinement
      .compare_module_results(
        object.module, mod
      )).to be true
  end

  it "comparison works with undercased symbols" do
    object = my_class.new(module: described_class)

    expect(WithComparisonRefinement
      .compare_module_results(
        object.module, :comparison
      )).to be true
  end

  it "comparison works with demodulized underscore symbol" do
    object = my_class.new(
      module: NestedComparisonModules::Banana::Strawberry
    )

    expect(WithComparisonRefinement
      .compare_module_results(
        object.module, :strawberry
      )).to be true
  end

  it "comparison works with partially nested underscore symbol" do
    object = my_class.new(
      module: NestedComparisonModules::Banana::Strawberry
    )

    expect(WithComparisonRefinement
      .compare_module_results(
        object.module, :banana_strawberry
      )).to be true
  end

  it "comparison works with fully nested underscore symbol" do
    object = my_class.new(
      module: NestedComparisonModules::Banana::Strawberry
    )

    expect(
      WithComparisonRefinement.compare_module_results(
        object.module,
        :nested_comparison_modules_banana_strawberry
      )
    ).to be true
  end

  it "comparison works with CamelCase unqualified symbol" do
    object = my_class.new(
      module: NestedComparisonModules::Banana::Strawberry
    )

    expect(
      WithComparisonRefinement.compare_module_results(
        object.module, :Strawberry
      )
    ).to be true
  end

  it "comparison works with CamelCase unqualified string" do
    object = my_class.new(
      module: NestedComparisonModules::Banana::Strawberry
    )

    expect(
      WithComparisonRefinement.compare_module_results(
        object.module, "Strawberry"
      )
    ).to be true
  end

  it "#compare" do
    mod = described_class
    object = my_class.new
    object.module = mod

    expect(
      described_class.compare(mod, :comparison)
    ).to be true
  end

  it "#compare works with nested underscore symbols" do
    mod = NestedComparisonModules::Banana::Strawberry
    object = my_class.new
    object.module = mod

    expect(
      described_class.compare(
        mod, :banana_strawberry
      )
    ).to be true
  end

  describe "ambiguous names" do
    it "flat module matches its own name" do
      expect(WithComparisonRefinement
        .compare_module_results(
          ComparisonAmbiguous::StatusA, :status_a
        )).to be true
    end

    it "nested module matches its own name" do
      expect(WithComparisonRefinement
        .compare_module_results(
          ComparisonAmbiguous::Nested::StatusA,
          :status_a
        )).to be true
    end

    it "nested module matches its unique name" do
      expect(WithComparisonRefinement
        .compare_module_results(
          ComparisonAmbiguous::Nested::StatusA,
          :nested_status_a
        )).to be true
    end
  end
end
