# frozen_string_literal: true

module ActiveEntity
  module Associations
    module Embeds
      # = Active Entity Has Many Association
      # This is the proxy that handles a has many association.
      #
      # If the association has a <tt>:through</tt> option further specialization
      # is provided by its child HasManyThroughAssociation.
      class EmbedsManyAssociation < CollectionAssociation #:nodoc:
      end
    end
  end
end
