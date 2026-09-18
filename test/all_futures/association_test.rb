# frozen_string_literal: true

require "test_helper"

# rubocop:disable Lint/ConstantDefinitionInBlock
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

  it "destroys children with dependent: :destroy" do
    class DoomedAgency < AllFutures::Base
      embeds_many :minions, dependent: :destroy
    end

    class Minion < AllFutures::Base
      attribute :doomed_agency_id
      embedded_in :doomed_agency
    end

    agency = DoomedAgency.new
    minion = agency.minions.build
    agency.save

    assert minion.persisted?

    agency.destroy

    assert minion.destroyed?
    assert_raises(AllFutures::RecordNotFound) { Minion.find(minion.id) }
  end

  it "deletes children with dependent: :delete" do
    class PurgedAgency < AllFutures::Base
      embeds_many :drones, dependent: :delete
    end

    class Drone < AllFutures::Base
      attribute :purged_agency_id
      embedded_in :purged_agency
    end

    agency = PurgedAgency.new
    drone = agency.drones.build
    agency.save

    agency.destroy

    assert_raises(AllFutures::RecordNotFound) { Drone.find(drone.id) }
  end

  it "nullifies foreign keys with dependent: :nullify" do
    class LenientAgency < AllFutures::Base
      embeds_many :contractors, dependent: :nullify
    end

    class Contractor < AllFutures::Base
      attribute :lenient_agency_id
      embedded_in :lenient_agency
    end

    agency = LenientAgency.new
    contractor = agency.contractors.build
    agency.save

    assert_equal agency.id, contractor.lenient_agency_id

    agency.destroy

    assert_nil Contractor.find(contractor.id).lenient_agency_id
  end

  it "raises DeleteRestrictionError with dependent: :restrict_with_exception" do
    class StubbornAgency < AllFutures::Base
      embeds_many :lifers, dependent: :restrict_with_exception
    end

    class Lifer < AllFutures::Base
      attribute :stubborn_agency_id
      embedded_in :stubborn_agency
    end

    agency = StubbornAgency.new
    agency.lifers.build
    agency.save

    assert_raises(AllFutures::DeleteRestrictionError) { agency.destroy }
    assert StubbornAgency.find(agency.id)
  end

  it "aborts destroy and adds errors with dependent: :restrict_with_error" do
    class CarefulAgency < AllFutures::Base
      embeds_many :tenants, dependent: :restrict_with_error
    end

    class Tenant < AllFutures::Base
      attribute :careful_agency_id
      embedded_in :careful_agency
    end

    agency = CarefulAgency.new
    tenant = agency.tenants.build
    agency.save

    refute agency.destroy
    refute agency.destroyed?
    assert agency.errors[:base].any?
    assert CarefulAgency.find(agency.id)
    assert Tenant.find(tenant.id)
  end

  it "persists changed children on save with autosave: true" do
    class AutoAgency < AllFutures::Base
      embeds_many :auto_agents, autosave: true
    end

    class AutoAgent < AllFutures::Base
      attribute :auto_agency_id
      attribute :codename, :string
      embedded_in :auto_agency
    end

    agency = AutoAgency.new
    agent = agency.auto_agents.build(codename: "alpha")
    agency.save

    assert_equal "alpha", AutoAgent.find(agent.id).codename

    agent.codename = "beta"
    agency.save

    assert_equal "beta", AutoAgent.find(agent.id).codename
  end

  it "rehydrates embeds_many after find" do
    class IndexedBureau < AllFutures::Base
      embeds_many :operatives
    end

    class Operative < AllFutures::Base
      attribute :indexed_bureau_id
      attribute :callsign, :string
      embedded_in :indexed_bureau
    end

    bureau = IndexedBureau.new
    bureau.operatives.build(callsign: "fox")
    bureau.operatives.build(callsign: "viper")
    bureau.save

    found = IndexedBureau.find(bureau.id)
    assert_equal 2, found.operatives.size
    assert_equal ["fox", "viper"].sort, found.operatives.map(&:callsign).sort
  end

  it "rehydrates embeds_one after find" do
    class IndexedDesk < AllFutures::Base
      embeds_one :chief
    end

    class Chief < AllFutures::Base
      attribute :indexed_desk_id
      attribute :title, :string
      embedded_in :indexed_desk
    end

    desk = IndexedDesk.new
    desk.build_chief(title: "Director")
    desk.save

    found = IndexedDesk.find(desk.id)
    assert found.chief
    assert_equal "Director", found.chief.title
  end

  it "indexes children saved independently against a parent" do
    class IndexedStation < AllFutures::Base
      embeds_many :radios
    end

    class Radio < AllFutures::Base
      attribute :indexed_station_id
      attribute :channel, :string
      embedded_in :indexed_station
    end

    station = IndexedStation.create
    Radio.create(indexed_station_id: station.id, channel: "alpha")

    found = IndexedStation.find(station.id)
    assert_equal 1, found.radios.size
    assert_equal "alpha", found.radios.first.channel
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock
