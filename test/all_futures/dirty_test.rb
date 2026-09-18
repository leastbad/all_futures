# frozen_string_literal: true

require "test_helper"

# rubocop:disable Lint/ConstantDefinitionInBlock
describe AllFutures::Dirty do
  class DirtyWidget < AllFutures::Base
    attribute :name, :string
    attribute :score, :integer, default: 0
  end

  it "starts clean when created with attributes" do
    widget = DirtyWidget.create(name: "fresh")
    refute widget.dirty?
  end

  it "tracks changes after assignment" do
    widget = DirtyWidget.create(name: "fresh")
    widget.name = "stale"

    assert widget.dirty?
    assert widget.attribute_changed?(:name)
    assert_equal ["fresh", "stale"], widget.attribute_change(:name)
  end

  it "restore_attribute undoes unsaved changes" do
    widget = DirtyWidget.create(name: "fresh")
    widget.name = "stale"
    widget.restore_attribute(:name)

    assert_equal "fresh", widget.name
    refute widget.dirty?
  end

  it "restore_attributes undoes multiple unsaved changes" do
    widget = DirtyWidget.create(name: "fresh", score: 1)
    widget.name = "stale"
    widget.score = 99
    widget.restore_attributes

    assert_equal "fresh", widget.name
    assert_equal 1, widget.score
    refute widget.dirty?
  end

  it "rollback_attribute reverts to the previously saved value without saving" do
    widget = DirtyWidget.create(name: "v1")
    widget.update(name: "v2")
    widget.name = "v3"
    widget.rollback_attribute(:name)

    assert_equal "v1", widget.name
    assert_equal "v2", DirtyWidget.find(widget.id).name
  end

  it "rollback_attributes! persists the previous values" do
    widget = DirtyWidget.create(name: "v1", score: 1)
    widget.update(name: "v2", score: 2)
    widget.name = "v3"
    widget.score = 3
    widget.rollback_attributes!

    assert_equal "v1", DirtyWidget.find(widget.id).name
    assert_equal 1, DirtyWidget.find(widget.id).score
  end

  it "reload clears in-memory changes and restores Redis state" do
    widget = DirtyWidget.create(name: "stored")
    widget.name = "local only"
    widget.reload

    assert_equal "stored", widget.name
    refute widget.dirty?
  end

  it "reload keeps dirty tracking alive for subsequent edits" do
    widget = DirtyWidget.create(name: "stored")
    widget.reload
    widget.name = "after reload"

    assert widget.dirty?
    assert widget.save
    assert_equal "after reload", DirtyWidget.find(widget.id).name
  end

  it "reports saved_changes after a successful update" do
    widget = DirtyWidget.create(name: "before")
    widget.update(name: "after")

    assert widget.saved_changes?
    assert_includes widget.saved_changes.keys, "name"
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock
