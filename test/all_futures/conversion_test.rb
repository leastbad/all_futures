# frozen_string_literal: true

require "test_helper"

class ConversionModel < AllFutures::Base
end

# largely copied from ActiveModel:Test::Cases::ConversionTest
describe AllFutures::Base do
  it "to_model default implementation returns self" do
    example = ConversionModel.new
    assert_equal example, example.to_model
  end

  it "to_key default implementation returns nil for new records" do
    assert_nil ConversionModel.new.to_key
  end

  it "to_key default implementation returns the id in an array for persisted records" do
    example = ConversionModel.new(id: 1)
    example.save

    assert_equal [example.id], example.to_key
  end

  it "to_param default implementation returns nil for new records" do
    assert_nil ConversionModel.new.to_param
  end

  it "to_param default implementation returns a string of ids for persisted records" do
    example = ConversionModel.new(id: 1)
    example.save

    assert_equal example.id, example.to_param
  end

  it "to_param returns nil if to_key is nil" do
    klass = Class.new(ConversionModel) do
      def persisted?
        true
      end
    end

    assert_nil klass.new.to_param
  end

  it "to_partial_path default implementation returns a string giving a relative path" do
    assert_equal "conversion_models/conversion_model", ConversionModel.new.to_partial_path
  end
end
