# frozen_string_literal: true

require "test_helper"

class ExampleModel < AllFutures::Base
end

describe AllFutures::Base do
  it "returns a valid cache key for a new record" do
    example = ExampleModel.new

    assert_equal "example_models/new", example.cache_key
  end

  it "returns a valid cache key for a persisted record" do
    example = ExampleModel.create

    assert_equal "example_models/#{example.id}", example.cache_key
  end
end
