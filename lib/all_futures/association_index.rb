# frozen_string_literal: true

module AllFutures
  # Maintains Redis SETs that index embedded children by owner so associations
  # can be lazy-loaded after find without scanning every key of the child class.
  #
  # Key shape: "OwnerClass:owner_id:association_name" => SET of child ids
  module AssociationIndex
    module_function

    def key(owner_class, owner_id, association_name)
      "#{owner_class.name}:#{owner_id}:#{association_name}"
    end

    def add(owner_class, owner_id, association_name, child_id)
      return if owner_id.blank? || child_id.blank?
      Kredis.redis.sadd(key(owner_class, owner_id, association_name), child_id.to_s)
    end

    def remove(owner_class, owner_id, association_name, child_id)
      return if owner_id.blank? || child_id.blank?
      Kredis.redis.srem(key(owner_class, owner_id, association_name), child_id.to_s)
    end

    def clear(owner_class, owner_id, association_name)
      return if owner_id.blank?
      Kredis.redis.del(key(owner_class, owner_id, association_name))
    end

    def member_ids(owner_class, owner_id, association_name)
      return [] if owner_id.blank?
      Array(Kredis.redis.smembers(key(owner_class, owner_id, association_name)))
    end

    def hydrate(association)
      return if association.instance_variable_get(:@af_hydrated)
      association.instance_variable_set(:@af_hydrated, true)

      owner = association.owner
      return unless owner.is_a?(AllFutures::Base) && owner.persisted?

      reflection = association.reflection
      return unless [:embeds_many, :embeds_one].include?(reflection.macro)

      ids = member_ids(owner.class, owner.id, reflection.name)
      return if ids.empty?

      existing_ids = Array.wrap(association.target).compact.map { |r| r.id.to_s }

      ids.each do |child_id|
        next if existing_ids.include?(child_id.to_s)

        begin
          record = reflection.klass.find(child_id)
        rescue AllFutures::RecordNotFound
          remove(owner.class, owner.id, reflection.name, child_id)
          next
        end

        if reflection.macro == :embeds_many
          association.add_to_target(record, true)
        else
          association.target = record
          association.set_inverse_instance(record)
        end
      end
    end
  end
end
