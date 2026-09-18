# frozen_string_literal: true

require "test_helper"

class ExampleModel < AllFutures::Base
  attribute :name, :string
  attribute :age, :integer, default: 21
  @count = nil
end

describe AllFutures::Base do
  it "can be initialized" do
    assert ExampleModel.new
  end

  it "presents new records" do
    example = ExampleModel.new

    assert example.new_record?
    refute example.persisted?
  end

  it "can be saved" do
    example = ExampleModel.new

    assert example.save
    assert example.persisted?
    refute example.new_record?
  end

  it "can be updated" do
    example = ExampleModel.new
    example.update(age: 31)

    assert example.persisted?
    assert example.age == 31
  end

  it "persists updated attributes across find" do
    example = ExampleModel.create(name: "before")
    example.name = "after"

    assert example.save
    assert_equal "after", ExampleModel.find(example.id).name
  end

  it "persists attributes updated via update across find" do
    example = ExampleModel.create(age: 21)
    example.update(age: 42)

    assert_equal 42, ExampleModel.find(example.id).age
  end

  it "isn't dirty after find, but tracks changes made afterwards" do
    example = ExampleModel.create(name: "clean")
    found = ExampleModel.find(example.id)

    refute found.dirty?

    found.name = "edited"

    assert found.dirty?
    assert found.save
    assert_equal "edited", ExampleModel.find(example.id).name
  end

  it "persists rolled back attributes with rollback_attribute!" do
    example = ExampleModel.create(name: "original")
    example.update(name: "changed")
    example.rollback_attribute!(:name)

    assert_equal "original", example.name
    assert_equal "original", ExampleModel.find(example.id).name
  end

  it "can be destroyed" do
    example = ExampleModel.new
    example.save

    assert ExampleModel.find(example.id)

    example.destroy

    assert example.destroyed?

    assert_raises(AllFutures::RecordNotFound) do
      ExampleModel.find(example.id)
    end
  end
end
