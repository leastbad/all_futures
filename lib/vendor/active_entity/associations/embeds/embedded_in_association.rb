# frozen_string_literal: true

module ActiveEntity
  module Associations
    module Embeds
      # = Active Entity Belongs To Association
      class EmbeddedInAssociation < SingularAssociation #:nodoc:
        def default(&block)
          writer(owner.instance_exec(&block)) if reader.nil?
        end

        private

          def replace(record)
            if record
              raise_on_type_mismatch!(record)
              set_inverse_instance(record)
            end

            self.target = record
          end
          # NOTE - for now, we're only supporting inverse setting from belongs_to back onto
          # has_one associations.
          def invertible_for?(record)
            inverse = inverse_reflection_for(record)
            inverse&.embeds_one?
          end
      end
    end
  end
end
