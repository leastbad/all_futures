# frozen_string_literal: true

module ActiveEntity
  module Associations
    module Embeds
      # = Active Entity Has One Association
      class EmbedsOneAssociation < SingularAssociation #:nodoc:
        private

          def replace(record)
            self.target =
              if record.is_a? reflection.klass
                record
              elsif record.nil?
                nil
              elsif record.respond_to?(:to_h)
                build_record(record.to_h)
              end
          rescue => ex
            raise_on_type_mismatch!(record)
            raise ex
          end
      end
    end
  end
end
