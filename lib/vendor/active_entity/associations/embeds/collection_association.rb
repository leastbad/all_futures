# frozen_string_literal: true

module ActiveEntity
  module Associations
    module Embeds
      # = Active Entity Association Collection
      #
      # CollectionAssociation is an abstract class that provides common stuff to
      # ease the implementation of association proxies that represent
      # collections. See the class hierarchy in Association.
      #
      #   CollectionAssociation:
      #     HasManyAssociation => has_many
      #       HasManyThroughAssociation + ThroughAssociation => has_many :through
      #
      # The CollectionAssociation class provides common methods to the collections
      # defined by +has_and_belongs_to_many+, +has_many+ or +has_many+ with
      # the +:through association+ option.
      #
      # You need to be careful with assumptions regarding the target: The proxy
      # does not fetch records from the database until it needs them, but new
      # ones created with +build+ are added to the target. So, the target may be
      # non-empty and still lack children waiting to be read from the database.
      # If you look directly to the database you cannot assume that's the entire
      # collection because new records may have been added to the target, etc.
      #
      # If you need to work on all current children, new and existing records,
      # +load_target+ and the +loaded+ flag are your friends.
      class CollectionAssociation < Association #:nodoc:
        def initialize(owner, reflection)
          super

          @target = []
        end

        # Implements the reader method, e.g. foo.items for Foo.has_many :items
        def reader
          @proxy ||= CollectionProxy.new(klass, self)
        end

        # Implements the writer method, e.g. foo.items= for Foo.has_many :items
        def writer(records)
          replace(records)
        end

        def find(&block)
          target.find(&block)
        end

        def build(attributes = {}, &block)
          if attributes.is_a?(Array)
            attributes.collect { |attr| build(attr, &block) }
          else
            add_to_target(build_record(attributes, &block))
          end
        end

        # Add +records+ to this association. Returns +self+ so method calls may
        # be chained. Since << flattens its argument list and inserts each record,
        # +push+ and +concat+ behave identically.
        def concat(*records)
          records = records.flatten
          concat_records(records)
        end

        # Removes all records from the association without calling callbacks
        # on the associated records. It honors the +:dependent+ option. However
        # if the +:dependent+ value is +:destroy+ then in that case the +:delete_all+
        # deletion strategy for the association is applied.
        #
        # You can force a particular deletion strategy by passing a parameter.
        #
        # Example:
        #
        # @author.books.delete_all(:nullify)
        # @author.books.delete_all(:delete_all)
        #
        # See delete for more info.
        def delete_all
          target.clear
        end
        alias destroy_all delete_all

        # Removes +records+ from this association calling +before_remove+ and
        # +after_remove+ callbacks.
        #
        # This method is abstract in the sense that +delete_records+ has to be
        # provided by descendants. Note this method does not imply the records
        # are actually removed from the database, that depends precisely on
        # +delete_records+. They are in any case removed from the collection.
        def delete(*records)
          records.each do |record|
            target.delete(record)
          end
        end
        alias destroy delete

        # Returns the size of the collection by executing a SELECT COUNT(*)
        # query if the collection hasn't been loaded, and calling
        # <tt>collection.size</tt> if it has.
        #
        # If the collection has been already loaded +size+ and +length+ are
        # equivalent. If not and you are going to need the records anyway
        # +length+ will take one less query. Otherwise +size+ is more efficient.
        #
        # This method is abstract in the sense that it relies on
        # +count_records+, which is a method descendants have to provide.
        def size
          target.size
        end

        # Returns true if the collection is empty.
        #
        # If the collection has been loaded
        # it is equivalent to <tt>collection.size.zero?</tt>. If the
        # collection has not been loaded, it is equivalent to
        # <tt>collection.exists?</tt>. If the collection has not already been
        # loaded and you are going to fetch the records anyway it is better to
        # check <tt>collection.length.zero?</tt>.
        def empty?
          size.zero?
        end

        # Replace this collection with +other_array+. This will perform a diff
        # and delete/add only records that have changed.
        def replace(other_array)
          records = other_array.map do |val|
            if val.is_a? reflection.klass
              val
            elsif val.nil?
              next
            elsif val.respond_to?(:to_h)
              build_record(val.to_h)
            end
          rescue => ex
            raise_on_type_mismatch!(val)
            raise ex
          end

          target.replace records
        end

        def include?(record)
          if record.is_a?(reflection.klass)
            target.include?(record)
          else
            false
          end
        end

        def add_to_target(record, skip_callbacks = false, &block)
          # index = @target.index(record)
          # replace_on_target(record, index, skip_callbacks, &block)
          replace_on_target(record, nil, skip_callbacks, &block)
        end

        private

          def concat_records(records)
            records.each do |record|
              r =
                if record.is_a? reflection.klass
                  record
                elsif record.nil?
                  nil
                elsif record.respond_to?(:to_h)
                  build_record(record.to_h)
                end
              add_to_target(r)
            rescue => ex
              raise_on_type_mismatch!(record)
              raise ex
            end

            records
          end

          def replace_on_target(record, index, skip_callbacks)
            callback(:before_add, record) unless skip_callbacks

            set_inverse_instance(record)

            yield(record) if block_given?

            if index
              target[index] = record
            else
              target << record
            end

            callback(:after_add, record) unless skip_callbacks

            record
          end

          def callback(method, record)
            callbacks_for(method).each do |callback|
              callback.call(method, owner, record)
            end
          end

          def callbacks_for(callback_name)
            full_callback_name = "#{callback_name}_for_#{reflection.name}"
            owner.class.send(full_callback_name)
          end
      end
    end
  end
end
