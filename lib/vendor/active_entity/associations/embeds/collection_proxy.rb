# frozen_string_literal: true

module ActiveEntity
  module Associations
    module Embeds
      # Association proxies in Active Entity are middlemen between the object that
      # holds the association, known as the <tt>@owner</tt>, and the actual associated
      # object, known as the <tt>@target</tt>. The kind of association any proxy is
      # about is available in <tt>@reflection</tt>. That's an instance of the class
      # ActiveEntity::Reflection::AssociationReflection.
      #
      # For example, given
      #
      #   class Blog < ActiveEntity::Base
      #     has_many :posts
      #   end
      #
      #   blog = Blog.first
      #
      # the association proxy in <tt>blog.posts</tt> has the object in +blog+ as
      # <tt>@owner</tt>, the collection of its posts as <tt>@target</tt>, and
      # the <tt>@reflection</tt> object represents a <tt>:has_many</tt> macro.
      #
      # This class delegates unknown methods to <tt>@target</tt> via
      # <tt>method_missing</tt>.
      #
      # The <tt>@target</tt> object is not \loaded until needed. For example,
      #
      #   blog.posts.count
      #
      # is computed directly through SQL and does not trigger by itself the
      # instantiation of the actual post records.
      class CollectionProxy
        include Enumerable

        attr_reader :klass
        alias :model :klass

        delegate :to_xml, :encode_with, :length, :each, :join,
                 :[], :&, :|, :+, :-, :sample, :reverse, :rotate, :compact, :in_groups, :in_groups_of,
                 :find, :last, :take, :blank?, :present?, :empty?, :any?, :one?, :many?, :include?,
                 :to_sentence, :to_formatted_s, :as_json,
                 :shuffle, :split, :slice, :index, :rindex, :size, to: :records

        def initialize(klass, association)
          @klass = klass

          @association = association

          extensions = association.extensions
          extend(*extensions) if extensions.any?
        end

        # Initializes new record from relation while maintaining the current
        # scope.
        #
        # Expects arguments in the same format as {ActiveEntity::Base.new}[rdoc-ref:Core.new].
        #
        #   users = User.where(name: 'DHH')
        #   user = users.new # => #<User id: nil, name: "DHH", created_at: nil, updated_at: nil>
        #
        # You can also pass a block to new with the new record as argument:
        #
        #   user = users.new { |user| user.name = 'Oscar' }
        #   user.name # => Oscar
        def new(attributes = nil, &block)
          klass.new(attributes, &block)
        end

        alias build new

        def pretty_print(q)
          q.pp(records)
        end

        def inspect
          entries = records.take([size, 11].compact.min).map!(&:inspect)

          entries[10] = "..." if entries.size == 11

          "#<#{self.class.name} [#{entries.join(', ')}]>"
        end

        # Returns +true+ if the association has been loaded, otherwise +false+.
        #
        #   person.pets.loaded? # => false
        #   person.pets
        #   person.pets.loaded? # => true
        def loaded?
          @association.loaded?
        end

        # Returns a new object of the collection type that has been instantiated
        # with +attributes+ and linked to this object, but have not yet been saved.
        # You can pass an array of attributes hashes, this will return an array
        # with the new objects.
        #
        #   class Person
        #     has_many :pets
        #   end
        #
        #   person.pets.build
        #   # => #<Pet id: nil, name: nil, person_id: 1>
        #
        #   person.pets.build(name: 'Fancy-Fancy')
        #   # => #<Pet id: nil, name: "Fancy-Fancy", person_id: 1>
        #
        #   person.pets.build([{name: 'Spook'}, {name: 'Choo-Choo'}, {name: 'Brain'}])
        #   # => [
        #   #      #<Pet id: nil, name: "Spook", person_id: 1>,
        #   #      #<Pet id: nil, name: "Choo-Choo", person_id: 1>,
        #   #      #<Pet id: nil, name: "Brain", person_id: 1>
        #   #    ]
        #
        #   person.pets.size  # => 5 # size of the collection
        #   person.pets.count # => 0 # count from database
        def build(attributes = {}, &block)
          @association.build(attributes, &block)
        end
        alias_method :new, :build

        # Add one or more records to the collection by setting their foreign keys
        # to the association's primary key. Since #<< flattens its argument list and
        # inserts each record, +push+ and #concat behave identically. Returns +self+
        # so method calls may be chained.
        #
        #   class Person < ActiveEntity::Base
        #     has_many :pets
        #   end
        #
        #   person.pets.size # => 0
        #   person.pets.concat(Pet.new(name: 'Fancy-Fancy'))
        #   person.pets.concat(Pet.new(name: 'Spook'), Pet.new(name: 'Choo-Choo'))
        #   person.pets.size # => 3
        #
        #   person.id # => 1
        #   person.pets
        #   # => [
        #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
        #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
        #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
        #   #    ]
        #
        #   person.pets.concat([Pet.new(name: 'Brain'), Pet.new(name: 'Benny')])
        #   person.pets.size # => 5
        def concat(*records)
          @association.concat(*records)
        end

        # Replaces this collection with +other_array+. This will perform a diff
        # and delete/add only records that have changed.
        #
        #   class Person < ActiveEntity::Base
        #     has_many :pets
        #   end
        #
        #   person.pets
        #   # => [#<Pet id: 1, name: "Gorby", group: "cats", person_id: 1>]
        #
        #   other_pets = [Pet.new(name: 'Puff', group: 'celebrities']
        #
        #   person.pets.replace(other_pets)
        #
        #   person.pets
        #   # => [#<Pet id: 2, name: "Puff", group: "celebrities", person_id: 1>]
        #
        # If the supplied array has an incorrect association type, it raises
        # an <tt>ActiveEntity::AssociationTypeMismatch</tt> error:
        #
        #   person.pets.replace(["doo", "ggie", "gaga"])
        #   # => ActiveEntity::AssociationTypeMismatch: Pet expected, got String
        def replace(other_array)
          @association.replace(other_array)
        end

        def delete_all
          @association.delete_all
        end
        alias destroy_all delete_all

        def delete(*records)
          @association.delete(*records)
        end
        alias destroy delete

        # Equivalent to +delete_all+. The difference is that returns +self+, instead
        # of an array with the deleted objects, so methods can be chained. See
        # +delete_all+ for more information.
        # Note that because +delete_all+ removes records by directly
        # running an SQL query into the database, the +updated_at+ column of
        # the object is not changed.
        def clear
          delete_all
          self
        end

        def proxy_association
          @association
        end

        # Equivalent to <tt>Array#==</tt>. Returns +true+ if the two arrays
        # contain the same number of elements and if each element is equal
        # to the corresponding element in the +other+ array, otherwise returns
        # +false+.
        #
        #   class Person < ActiveEntity::Base
        #     has_many :pets
        #   end
        #
        #   person.pets
        #   # => [
        #   #      #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
        #   #      #<Pet id: 2, name: "Spook", person_id: 1>
        #   #    ]
        #
        #   other = person.pets.to_ary
        #
        #   person.pets == other
        #   # => true
        #
        #   other = [Pet.new(id: 1), Pet.new(id: 2)]
        #
        #   person.pets == other
        #   # => false
        def ==(other)
          records == other
        end

        ##
        # :method: to_ary
        #
        # :call-seq:
        #   to_ary()
        #
        # Returns a new array of objects from the collection. If the collection
        # hasn't been loaded, it fetches the records from the database.
        #
        #   class Person < ActiveEntity::Base
        #     has_many :pets
        #   end
        #
        #   person.pets
        #   # => [
        #   #       #<Pet id: 4, name: "Benny", person_id: 1>,
        #   #       #<Pet id: 5, name: "Brain", person_id: 1>,
        #   #       #<Pet id: 6, name: "Boss",  person_id: 1>
        #   #    ]
        #
        #   other_pets = person.pets.to_ary
        #   # => [
        #   #       #<Pet id: 4, name: "Benny", person_id: 1>,
        #   #       #<Pet id: 5, name: "Brain", person_id: 1>,
        #   #       #<Pet id: 6, name: "Boss",  person_id: 1>
        #   #    ]
        #
        #   other_pets.replace([Pet.new(name: 'BooGoo')])
        #
        #   other_pets
        #   # => [#<Pet id: nil, name: "BooGoo", person_id: 1>]
        #
        #   person.pets
        #   # This is not affected by replace
        #   # => [
        #   #       #<Pet id: 4, name: "Benny", person_id: 1>,
        #   #       #<Pet id: 5, name: "Brain", person_id: 1>,
        #   #       #<Pet id: 6, name: "Boss",  person_id: 1>
        #   #    ]
        # Converts relation objects to Array.
        def to_ary
          records.dup
        end
        alias to_a to_ary

        def records # :nodoc:
          @association.target
        end

        # Adds one or more +records+ to the collection by setting their foreign keys
        # to the association's primary key. Returns +self+, so several appends may be
        # chained together.
        #
        #   class Person < ActiveEntity::Base
        #     has_many :pets
        #   end
        #
        #   person.pets.size # => 0
        #   person.pets << Pet.new(name: 'Fancy-Fancy')
        #   person.pets << [Pet.new(name: 'Spook'), Pet.new(name: 'Choo-Choo')]
        #   person.pets.size # => 3
        #
        #   person.id # => 1
        #   person.pets
        #   # => [
        #   #      #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
        #   #      #<Pet id: 2, name: "Spook", person_id: 1>,
        #   #      #<Pet id: 3, name: "Choo-Choo", person_id: 1>
        #   #    ]
        def <<(*records)
          proxy_association.concat(records) && self
        end
        alias_method :push, :<<
        alias_method :append, :<<

        def prepend(*_args)
          raise NoMethodError, "prepend on association is not defined. Please use <<, push or append"
        end
      end
    end
  end
end
