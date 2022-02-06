# frozen_string_literal: true

require "test_helper"

# rubocop:disable Lint/ConstantDefinitionInBlock:
describe AllFutures::Association do
  it "allows creation of an embedded record" do
    class Government < AllFutures::Base
      embeds_one :spy
    end

    class Spy < AllFutures::Base
      attribute :government_id
      embedded_in :government
    end

    government = Government.new
    government.build_spy
    government.save
    assert government.persisted?
    assert government.spy.persisted?
    assert_equal government.id, government.spy.government_id
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock:
