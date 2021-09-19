class AllFutures < ActiveEntity::Base
  attr_accessor :id

  def initialize(attributes={})
    super
    unless @id
      @id = SecureRandom.uuid
      save
    end
  end

  def []=(attr_name, value)
    super
    save
  end

  def save
    Kredis.json("#{self.class.name}:#{@id}").value = self.attributes
    changes_applied
  end

  def self.find(id)
    raise ArgumentError unless id
    json = Kredis.json("#{name}:#{id}").value
    raise ActiveRecord::RecordNotFound unless json
    new json.merge(id: id)
  end
end