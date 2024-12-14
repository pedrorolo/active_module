# # frozen_string_literal: true
#
# require "cases/helper"
#
#
# module ActiveRecord
#   class ModuleTypeTest < ActiveRecord::TestCase
#     module StrategyA; end
#
#     module StrategyB; end
#
#     module Nested
#       module StrategyA; end
#     end
#
#     module RandomModule; end
#
#     def active_record_class
#       Class.new(Base) {
#         self.table_name = "authors"
#         attribute :name, :module, possible_modules: [StrategyA, StrategyB, Nested::StrategyA]
#       }
#     end
#
#     test "it is possible to assign and query using modules" do
#       object = active_record_class.create!(name: StrategyA)
#       expect().to eq object.reload.name    StrategyA
#       assert_equal StrategyA, active_record_class.find_by(name: StrategyA).name
#     end
#
#     test "it is possible to assign and query using strings" do
#       object = active_record_class.create!(name: "StrategyB")
#       assert_equal StrategyB, object.reload.name
#       assert_equal StrategyB, active_record_class.find_by(name: "StrategyB").name
#     end
#
#     test "when using a module that is not in the list of possible modules we get failures" do
#       assert_raises ActiveModel::Type::Module::InvalidModuleValue do
#         active_record_class.create!(name: RandomModule)
#       end
#
#       assert_raises ActiveModel::Type::Module::InvalidModuleValue do
#         active_record_class.create!(name: "RandomModule")
#       end
#
#       assert_raises ActiveModel::Type::Module::InvalidModuleValue do
#         active_record_class.create!(name: "WrongStringThatIsNotAModule")
#       end
#
#       assert_raises ActiveModel::Type::Module::InvalidModuleValue do
#         active_record_class.where(name: RandomModule).load
#       end
#
#       assert_raises ActiveModel::Type::Module::InvalidModuleValue do
#         active_record_class.where(name: "RandomModule").load
#       end
#
#       assert_raises ActiveModel::Type::Module::InvalidModuleValue do
#         active_record_class.where(name: "WrongStringThatIsNotAModule").load
#       end
#     end
#
#     test "When using an ambiguous string the first "\
#           "possible module of the possible modules list is selected" do
#       object = active_record_class.create!(name: StrategyA)
#       assert_equal StrategyA, object.reload.name
#
#       class_with_other_order = Class.new(Base) {
#         self.table_name = "authors"
#         attribute :name, :module, possible_modules: [Nested::StrategyA, StrategyA, StrategyB]
#       }
#
#       object = class_with_other_order.create!(name: "StrategyA")
#       assert_equal Nested::StrategyA, object.reload.name
#     end
#   end
# end
#

RSpec.describe ActiveModule::Type do
  before do
    require "active_record"

    # silence_warnings do
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Base.logger = Logger.new(nil)
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    # end

    ActiveRecord::Base.connection.instance_eval do
      create_table :my_objects do |t|
        t.string :strategy
      end
    end
    ActiveModel::Type.register(:module, ActiveModule::Type)
    ActiveRecord::Type.register(:module, ActiveModule::Type)
  end

  module StrategyA; end

  module StrategyB; end

  module Nested
    module StrategyA; end
  end

  module RandomModule; end

  def active_record_class
    Class.new(ActiveRecord::Base) do
      self.table_name = "my_objects"
      attribute :name, :module, possible_modules: [StrategyA, StrategyB, Nested::StrategyA]
    end
  end

  it "it is possible to assign and query using modules" do
    object = active_record_class.create!(name: StrategyA)
    expect(object.reload.name).to eq StrategyA
    expect(active_record_class.find_by(name: StrategyA).name).to eq StrategyA
  end

  it "it is possible to assign and query using strings" do
    object = active_record_class.create!(name: "StrategyB")
    expect(StrategyB).to eq object.reload.name
    expect(StrategyB).to eq active_record_class.find_by(name: "StrategyB").name
  end

  it "when using a module that is not in the list of possible modules we get failures" do
    expect do
      active_record_class.create!(name: RandomModule)
    end.to raise_error(ActiveModel::Type::Module::InvalidModuleValue)

    expect do
      active_record_class.create!(name: "RandomModule")
    end.to raise_error(ActiveModel::Type::Module::InvalidModuleValue)

    expect do
      active_record_class.create!(name: "WrongStringThatIsNotAModule")
    end.to raise_error(ActiveModel::Type::Module::InvalidModuleValue)

    expect do
      active_record_class.where(name: RandomModule).load
    end.to raise_error(ActiveModel::Type::Module::InvalidModuleValue)

    expect do
      active_record_class.where(name: "RandomModule").load
    end.to raise_error(ActiveModel::Type::Module::InvalidModuleValue)

    expect do
      active_record_class.where(name: "WrongStringThatIsNotAModule").load
    end.to raise_error(ActiveModel::Type::Module::InvalidModuleValue)
  end

  it "When using an ambiguous string the first "\
        "possible module of the possible modules list is selected" do
    object = active_record_class.create!(name: StrategyA)
    expect(StrategyA).to eq object.reload.name

    class_with_other_order = Class.new(Base) do
      self.table_name = "authors"
      attribute :name, :module, possible_modules: [Nested::StrategyA, StrategyA, StrategyB]
    end

    object = class_with_other_order.create!(name: "StrategyA")
    expect(object.reload.name).to eq Nested::StrategyA
  end
end
