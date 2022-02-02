# frozen_string_literal: true

module AllFutures
  module Association
    def initialize_attributes(record, attributes = {})
      record.assign_attributes attributes if attributes.any?
      record._write_attribute(reflection.options[:foreign_key], owner.id) if owner.is_a?(AllFutures::Base)
      set_inverse_instance(record)
    end
  end
end

class ActiveEntity::Associations::Embeds::Association
  prepend AllFutures::Association
end
