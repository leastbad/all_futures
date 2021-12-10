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
