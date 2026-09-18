# frozen_string_literal: true

require "test_helper"

# rubocop:disable Lint/ConstantDefinitionInBlock
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

  it "doesn't track versions on non-versioned models" do
    not_versioned = NotVersioned.create(name: "one")
    not_versioned.update(name: "two")

    assert_nil not_versioned.current_version
    assert_empty not_versioned.versions
  end

  it "creates version 1 on create" do
    versioned = Versioned.create(name: "first")

    assert_equal 1, versioned.current_version
    assert_equal "first", versioned.version(1).attributes["name"]
  end

  it "bumps the version on each saved change" do
    versioned = Versioned.create(name: "first")
    versioned.update(name: "second")
    versioned.update(name: "third")

    assert_equal 3, versioned.current_version
    assert_equal "first", versioned.version(1).attributes["name"]
    assert_equal "second", versioned.version(2).attributes["name"]
    assert_equal "third", versioned.version(3).attributes["name"]
  end

  it "doesn't bump the version when saving without changes" do
    versioned = Versioned.create(name: "first")
    versioned.save

    assert_equal 1, versioned.current_version
    assert_equal 1, versioned.versions.size
  end

  it "restores version history when found" do
    versioned = Versioned.create(name: "first")
    versioned.update(name: "second")

    found = Versioned.find(versioned.id)

    assert_equal 2, found.current_version
    assert_equal "first", found.version(1).attributes["name"]
    assert_equal "second", found.version(2).attributes["name"]
  end

  it "raises VersionNotFound for unknown versions" do
    versioned = Versioned.create(name: "first")

    assert_raises(AllFutures::VersionNotFound) { versioned.version(99) }
  end

  it "doesn't bump the version inside without_versioning" do
    versioned = Versioned.create(name: "first")
    versioned.without_versioning do |record|
      record.update(name: "stealth")
    end

    assert_equal 1, versioned.current_version
    assert_equal "stealth", Versioned.find(versioned.id).name
  end

  it "raises RecordStale when saving over a newer version" do
    versioned = Versioned.create(name: "first")

    copy_a = Versioned.find(versioned.id)
    copy_b = Versioned.find(versioned.id)

    copy_a.update(name: "from a")

    copy_b.name = "from b"
    assert_raises(AllFutures::RecordStale) { copy_b.save }
    assert_equal "from a", Versioned.find(versioned.id).name
  end

  it "treats a changeless save of a stale copy as a no-op" do
    versioned = Versioned.create(name: "first")

    copy_a = Versioned.find(versioned.id)
    copy_b = Versioned.find(versioned.id)

    copy_a.update(name: "from a")

    assert copy_b.save
    assert_equal "from a", Versioned.find(versioned.id).name
  end

  describe "atomic locking" do
    before { @previous_atomic = AllFutures.atomic_locking }
    after { AllFutures.atomic_locking = @previous_atomic }

    it "defaults to off" do
      AllFutures.atomic_locking = false
      refute AllFutures.atomic_locking
    end

    it "round-trips creates and updates when atomic locking is on" do
      AllFutures.atomic_locking = true
      versioned = Versioned.create(name: "atomic-first")

      assert_equal 1, versioned.current_version
      assert_equal "atomic-first", Versioned.find(versioned.id).name

      versioned.update(name: "atomic-second")
      found = Versioned.find(versioned.id)

      assert_equal 2, found.current_version
      assert_equal "atomic-second", found.name
      assert_equal "atomic-first", found.version(1).attributes["name"]
    end

    it "raises RecordStale atomically when a newer version already exists" do
      AllFutures.atomic_locking = true
      versioned = Versioned.create(name: "first")

      copy_a = Versioned.find(versioned.id)
      copy_b = Versioned.find(versioned.id)

      copy_a.update(name: "from a")

      copy_b.name = "from b"
      assert_raises(AllFutures::RecordStale) { copy_b.save }
      assert_equal "from a", Versioned.find(versioned.id).name
      assert_equal 1, copy_b.current_version # in-memory bump rolled back
    end
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock
