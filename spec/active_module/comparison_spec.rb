# frozen_string_literal: true

module WithComparisonRefinement
  using ActiveModule::Comparison
  def self.compare_module_results(mod1, mod2)
    mod1 =~ mod2
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
                                   ActiveModule::Comparison]
    end
  end

  it "comparison works with symbols" do
    object = my_class.new(module: described_class)

    expect(WithComparisonRefinement
      .compare_module_results(object.module,
                              :Comparison)).to be true
  end

  it "comparison works with Strings" do
    object = my_class.new(module: described_class)

    expect(WithComparisonRefinement
      .compare_module_results(object.module,
                              "Comparison")).to be true
  end

  it "comparison works with Modules" do
    object = my_class.new(module: described_class)

    expect(WithComparisonRefinement
      .compare_module_results(object.module,
                              described_class)).to be true
  end
end
