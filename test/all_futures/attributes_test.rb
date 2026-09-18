# frozen_string_literal: true

require "test_helper"

# rubocop:disable Lint/ConstantDefinitionInBlock
describe "attributes, defaults, arrays, and validations" do
  class AttrWidget < AllFutures::Base
    attribute :title, :string, default: "untitled"
    attribute :count, :integer, default: 0
    attribute :active, :boolean, default: true
    attribute :tags, :string, array: true, default: []
    attribute :ratio, :float, default: 0.5

    validates :title, presence: true
    validates :count, numericality: {greater_than_or_equal_to: 0}
  end

  it "applies defaults on initialize" do
    widget = AttrWidget.new

    assert_equal "untitled", widget.title
    assert_equal 0, widget.count
    assert widget.active
    assert_equal [], widget.tags
    assert_in_delta 0.5, widget.ratio
  end

  it "persists array attributes" do
    widget = AttrWidget.create(tags: ["a", "b", "c"])
    found = AttrWidget.find(widget.id)

    assert_equal ["a", "b", "c"], found.tags
  end

  it "can append to array attributes and save" do
    widget = AttrWidget.create(tags: ["a"])
    widget.tags = widget.tags + ["b", "c"]
    widget.save

    assert_equal ["a", "b", "c"], AttrWidget.find(widget.id).tags
  end

  it "can save while invalid and keep the bad values" do
    widget = AttrWidget.create(title: "ok", count: 1)
    widget.title = ""
    widget.count = -5

    refute widget.valid?
    assert widget.save

    found = AttrWidget.find(widget.id)
    assert_equal "", found.title
    assert_equal(-5, found.count)
    refute found.valid?
  end

  it "exposes errors for invalid attributes without blocking save" do
    widget = AttrWidget.new(title: nil)
    refute widget.valid?
    assert widget.errors[:title].any?
    assert widget.save
  end

  it "casts boolean and float from strings on assign" do
    widget = AttrWidget.create
    widget.update(active: "0", ratio: "1.25")

    found = AttrWidget.find(widget.id)
    refute found.active
    assert_in_delta 1.25, found.ratio
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock
