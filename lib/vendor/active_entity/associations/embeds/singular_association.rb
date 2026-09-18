# frozen_string_literal: true

module ActiveEntity
  module Associations
    module Embeds
      class SingularAssociation < Association #:nodoc:
        # Implements the reader method, e.g. foo.bar for Foo.has_one :bar
        def reader
          target
        end

        # Implements the writer method, e.g. foo.bar= for Foo.belongs_to :bar
        def writer(record)
          replace(record)
        end

        def build(attributes = {}, &block)
          record = build_record(attributes, &block)
          set_new_record(record)
          record
        end

        private

          def replace(_record)
            raise NotImplementedError, "Subclasses must implement a replace(record) method"
          end

          def set_new_record(record)
            replace(record)
          end
      end
    end
  end
end
