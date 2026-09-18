# frozen_string_literal: true

require "test_helper"

# rubocop:disable Lint/ConstantDefinitionInBlock
describe "unicode and adversarial attribute values" do
  class GlyphWidget < AllFutures::Base
    attribute :label, :string
    attribute :tags, :string, array: true, default: []
  end

  [
    ["emoji", "🚀 All Futures 🦆"],
    ["rtl arabic", "مرحبا بالعالم"],
    ["hebrew", "שלום עולם"],
    ["zwj family", "👨‍👩‍👧‍👦"],
    ["combining marks", "e\u0301clair"], # e + combining acute
    ["mixed scripts", "Hello مرحبا 世界 🌍"],
    ["long string", "あ" * 2_000],
    ["newlines and tabs", "line1\nline2\ttrail"]
  ].each do |label, value|
    it "round-trips #{label} through save and find" do
      widget = GlyphWidget.create(label: value)
      found = GlyphWidget.find(widget.id)

      assert_equal value, found.label
    end
  end

  it "persists unicode array elements" do
    tags = ["🚀", "مرحبا", "世界", "👨‍💻"]
    widget = GlyphWidget.create(tags: tags)

    assert_equal tags, GlyphWidget.find(widget.id).tags
  end

  it "survives faker-generated unicode names across updates" do
    names = Array.new(5) { Faker::Name.name + " " + ["🔥", "✨", "ال", "漢"].sample }
    widget = GlyphWidget.create(label: names.first)

    names.drop(1).each do |name|
      widget.update(label: name)
      assert_equal name, GlyphWidget.find(widget.id).label
    end
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock
