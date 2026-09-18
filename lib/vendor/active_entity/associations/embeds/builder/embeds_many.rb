# frozen_string_literal: true

module ActiveEntity::Associations::Embeds::Builder # :nodoc:
  class EmbedsMany < CollectionAssociation #:nodoc:
    def self.macro
      :embeds_many
    end

    def self.valid_options(options)
      super + [:inverse_of, :index_errors]
    end
  end
end
