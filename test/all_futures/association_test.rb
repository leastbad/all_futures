# frozen_string_literal: true

require "test_helper"

# rubocop:disable Lint/ConstantDefinitionInBlock:
describe AllFutures::Association do
  it "allows creation of an embeds_one association" do
    class Government < AllFutures::Base
      embeds_one :spy
    end

    class Spy < AllFutures::Base
      attribute :government_id
      embedded_in :government
    end

    government = Government.new
    assert_nil government.spy
    government.build_spy
    assert government.spy
    assert government.spy.new_record?
    government.save
    assert government.persisted?
    assert government.spy.persisted?
    assert_equal government.id, government.spy.government_id
  end

  it "allows creation of an embeds_many association" do
    class Government < AllFutures::Base
      embeds_many :spies
    end

    class Spy < AllFutures::Base
      attribute :government_id
      embedded_in :government
    end

    government = Government.new
    government.spies.build
    government.spies.build
    government.save
    assert_equal 2, government.spies.size
    assert government.spies[0].persisted?
    assert government.spies[1].persisted?
    assert_equal government.id, government.spies[0].government_id
    assert_equal government.id, government.spies[1].government_id
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock:
