# frozen_string_literal: true

require "test_helper"

# rubocop:disable Lint/ConstantDefinitionInBlock:
describe AllFutures::Versions do
  class NotVersioned < AllFutures::Base
    attribute :name
  end

  class Versioned < AllFutures::Base
    enable_versioning!
    attribute :name
  end

  it "doesn't store versions for non-versioned models" do
    not_versioned = NotVersioned.new
    refute not_versioned.versioning_enabled?
  end

  it "stores versions of the model" do
    versioned = Versioned.new name: Faker::Name.name
    assert versioned.versioning_enabled?
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock:
