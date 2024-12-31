# frozen_string_literal: true

module WithEnumComparisonRefinement
  using ActiveModule::Enum::Comparison
  def self.compare_module_results(mod1, mod2)
    mod1 =~ mod2
  end
end

RSpec.describe ActiveModule::Enum::Comparison do
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
                                   ActiveModule::Enum::Comparison],
                enum_compatibility: true
    end
  end

  it "comparison works with symbols" do
    object = my_class.new(module: described_class)

    expect(WithEnumComparisonRefinement
      .compare_module_results(object.module,
                              :Comparison)).to be true
  end

  it "comparison works with Strings" do
    object = my_class.new(module: described_class)

    expect(WithEnumComparisonRefinement
      .compare_module_results(object.module,
                              "Comparison")).to be true
  end

  it "comparison works with Modules" do
    object = my_class.new(module: described_class)

    expect(WithEnumComparisonRefinement
      .compare_module_results(object.module,
                              described_class)).to be true
  end

  it "comparison works with undercased symbols" do
    object = my_class.new(module: described_class)

    expect(WithEnumComparisonRefinement
      .compare_module_results(object.module,
                              :comparison)).to be true
  end

  it "#compare" do
    object = my_class.new
    object.module = described_class
    expect(described_class.compare(object.module, :comparison))
      .to be true
  end
end
