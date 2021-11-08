class AllFutures < ActiveEntity::Base
  attr_accessor :id, :_redis_key, :_destroyed, :_persisted

  def initialize(attributes={})
    super
    @id ||= SecureRandom.uuid
    @_redis_key = "#{self.class.name}:#{@id}"
    @_destroyed = false
    @_persisted = Kredis.redis.exists @_redis_key
  end

  def []=(attr_name, value)
    super
    save
  end

  def save
    raise FrozenError.new("can't modify frozen attributes") if @_destroyed
    @_persisted = true
    Kredis.json(@_redis_key).value = self.attributes
    changes_applied
    true
  end

  def destroy
    @_destroyed = true
    Kredis.redis.del @_redis_key if persisted?
    self
  end

  def destroyed?
    @_destroyed
  end

  def new_record?
    !persisted?
  end

  def persisted?
    @_persisted
  end

  def self.create
    new.tap { |record| record.save }
  end

  def self.find(id)
    raise ActiveRecord::RecordNotFound.new("Couldn't find #{name} without an ID") unless id
    json = Kredis.json("#{name}:#{id}").value
    raise ActiveRecord::RecordNotFound.new("Couldn't find #{name} with ID #{id}") unless json
    new json.merge(id: id)
  end
end