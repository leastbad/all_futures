# frozen_string_literal: true

class AllFutures < ActiveEntity::Base
  include Callbacks
  attr_accessor :id, :redis_key, :destroyed, :new_record, :previously_new_record

  def self.create(attributes = {})
    new(attributes).tap { |record| record.save }
  end

  def self.find(id)
    raise ActiveRecord::RecordNotFound.new("Couldn't find #{name} without an ID") unless id
    json = Kredis.json("#{name}:#{id}").value
    raise ActiveRecord::RecordNotFound.new("Couldn't find #{name} with ID #{id}") unless json
    new json.merge(id: id)
  end

  def initialize(attributes = {})
    super do
      @id ||= SecureRandom.uuid
      @redis_key = "#{self.class.name}:#{@id}"
      @destroyed = false
      @new_record = !Kredis.redis.exists?(@redis_key)
      @previously_new_record = false
      @attributes.keys.each do |attr|
        define_singleton_method("saved_change_to_#{attr}?") { saved_change_to_attribute?(attr) }
        define_singleton_method("saved_change_to_#{attr}") { saved_change_to_attribute?(attr) ? [attribute_previously_was(attr), attribute_was(attr)] : nil }
      end
    end
  end

  def save
    raise FrozenError.new("can't modify frozen attributes") if @destroyed
    @previously_new_record = true if @new_record
    @new_record = false
    Kredis.json(@redis_key).value = attributes
    changes_applied
    true
  end

  def update(attrs = {})
    attrs.transform_keys!(&:to_s).each_key do |key|
      self[key] = attrs[key] if self[key] != attrs[key]
    end
    save if changes.any?
    true
  end

  def destroy
    Kredis.redis.del @redis_key if persisted?
    @destroyed = true
    self
  end

  def reload
    json = Kredis.json("#{self.class.name}:#{@id}").value
    attributes.each do |key, value|
      self[key] = json[key] if json[key] != value
    end
    clear_changes_information
    self
  end

  def destroyed?
    @destroyed
  end

  def new_record?
    @new_record
  end

  def persisted?
    !(@new_record || @destroyed)
  end

  def previously_new_record?
    @previously_new_record
  end

  def changed_attribute_names
    changed_attributes.keys
  end

  def has_changes_to_save?
    changes.any?
  end

  def saved_change_to_attribute?(attr)
    attribute_previously_was(attr) != attribute_was(attr)
  end

  def saved_changes
    attributes.select { |attr| saved_change_to_attribute? attr }
  end

  def saved_changes?
    saved_changes.any?
  end
end
