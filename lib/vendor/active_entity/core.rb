# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/string/filters"
require "active_support/parameter_filter"
require "concurrent/map"

module ActiveEntity
  module Core
    extend ActiveSupport::Concern

    included do
      ##
      # :singleton-method:
      #
      # Accepts a logger conforming to the interface of Log4r which is then
      # passed on to any new database connections made and which can be
      # retrieved on both a class and instance level by calling +logger+.
      mattr_accessor :logger, instance_writer: false

      ##
      # :singleton-method:
      # Determines whether to use Time.utc (using :utc) or Time.local (using :local) when pulling
      # dates and times from the database. This is set to :utc by default.
      mattr_accessor :default_timezone, instance_writer: false, default: :utc

      self.filter_attributes = []
    end

    module ClassMethods
      def initialize_generated_modules # :nodoc:
        generated_association_methods
      end

      def generated_association_methods # :nodoc:
        @generated_association_methods ||= begin
          mod = const_set(:GeneratedAssociationMethods, Module.new)
          private_constant :GeneratedAssociationMethods
          include mod

          mod
        end
      end

      # Returns columns which shouldn't be exposed while calling +#inspect+.
      def filter_attributes
        if defined?(@filter_attributes)
          @filter_attributes
        else
          superclass.filter_attributes
        end
      end

      # Specifies columns which shouldn't be exposed while calling +#inspect+.
      attr_writer :filter_attributes

      # Returns a string like 'Post(id:integer, title:string, body:text)'
      def inspect # :nodoc:
        if self == Base
          super
        else
          attr_list = attribute_types.map { |name, type| "#{name}: #{type.type}" } * ", "
          "#{super}#{ "(abstract)" if abstract_class? }(#{attr_list})"
        end
      end

      # Overwrite the default class equality method to provide support for decorated models.
      def ===(object) # :nodoc:
        object.is_a?(self)
      end
    end

    # New objects can be instantiated as either empty (pass no construction parameter) or pre-set with
    # attributes but not yet saved (pass a hash with key names matching the associated table column names).
    # In both instances, valid attribute keys are determined by the column names of the associated table --
    # hence you can't have attributes that aren't part of the table columns.
    #
    # ==== Example:
    #   # Instantiates a single new object
    #   User.new(first_name: 'Jamie')
    def initialize(attributes = nil)
      @attributes = self.class._default_attributes.deep_dup

      init_internals
      initialize_internals_callback

      assign_attributes(attributes) if attributes

      yield self if block_given?
      _run_initialize_callbacks

      enable_attr_readonly!
    end

    # Initialize an empty model object from +coder+. +coder+ should be
    # the result of previously encoding an Active Entity model, using
    # #encode_with.
    #
    #   class Post < ActiveEntity::Base
    #   end
    #
    #   old_post = Post.new(title: "hello world")
    #   coder = {}
    #   old_post.encode_with(coder)
    #
    #   post = Post.allocate
    #   post.init_with(coder)
    #   post.title # => 'hello world'
    def init_with(coder, &block)
      attributes = self.class.yaml_encoder.decode(coder)
      init_with_attributes(attributes, coder["new_record"], &block)
    end

    ##
    # Initialize an empty model object from +attributes+.
    # +attributes+ should be an attributes object, and unlike the
    # `initialize` method, no assignment calls are made per attribute.
    def init_with_attributes(attributes) # :nodoc:
      @attributes = attributes

      init_internals

      yield self if block_given?

      _run_find_callbacks
      _run_initialize_callbacks

      self
    end

    ##
    # :method: clone
    # Identical to Ruby's clone method.  This is a "shallow" copy.  Be warned that your attributes are not copied.
    # That means that modifying attributes of the clone will modify the original, since they will both point to the
    # same attributes hash. If you need a copy of your attributes hash, please use the #dup method.
    #
    #   user = User.first
    #   new_user = user.clone
    #   user.name               # => "Bob"
    #   new_user.name = "Joe"
    #   user.name               # => "Joe"
    #
    #   user.object_id == new_user.object_id            # => false
    #   user.name.object_id == new_user.name.object_id  # => true
    #
    #   user.name.object_id == user.dup.name.object_id  # => false

    ##
    # :method: dup
    # Duped objects have no id assigned and are treated as new records. Note
    # that this is a "shallow" copy as it copies the object's attributes
    # only, not its associations. The extent of a "deep" copy is application
    # specific and is therefore left to the application to implement according
    # to its need.
    # The dup method does not preserve the timestamps (created|updated)_(at|on).

    ##
    def initialize_dup(other) # :nodoc:
      @attributes = @attributes.deep_dup

      _run_initialize_callbacks

      super
    end

    # Populate +coder+ with attributes about this record that should be
    # serialized. The structure of +coder+ defined in this method is
    # guaranteed to match the structure of +coder+ passed to the #init_with
    # method.
    #
    # Example:
    #
    #   class Post < ActiveEntity::Base
    #   end
    #   coder = {}
    #   Post.new.encode_with(coder)
    #   coder # => {"attributes" => {"id" => nil, ... }}
    def encode_with(coder)
      self.class.yaml_encoder.encode(@attributes, coder)
      coder["active_entity_yaml_version"] = 2
    end

    # Returns true if +comparison_object+ is the same exact object, or +comparison_object+
    # is of the same type and +self+ has an ID and it is equal to +comparison_object.id+.
    #
    # Note that new records are different from any other record by definition, unless the
    # other record is the receiver itself. Besides, if you fetch existing records with
    # +select+ and leave the ID out, you're on your own, this predicate will return false.
    #
    # Note also that destroying a record preserves its ID in the model instance, so deleted
    # models are still comparable.
    def ==(comparison_object)
      super ||
        comparison_object.instance_of?(self.class) &&
        !id.nil? &&
        comparison_object.id == id
    end
    alias :eql? :==

    # Delegates to id in order to allow two records of the same type and id to work with something like:
    #   [ Person.find(1), Person.find(2), Person.find(3) ] & [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
    def hash
      if id
        self.class.hash ^ id.hash
      else
        super
      end
    end

    # Clone and freeze the attributes hash such that associations are still
    # accessible, even on destroyed records, but cloned models will not be
    # frozen.
    def freeze
      @attributes = @attributes.clone.freeze
      self
    end

    # Returns +true+ if the attributes hash has been frozen.
    def frozen?
      @attributes.frozen?
    end

    # Allows sort on objects
    def <=>(other_object)
      if other_object.is_a?(self.class)
        to_key <=> other_object.to_key
      else
        super
      end
    end

    def present? # :nodoc:
      true
    end

    def blank? # :nodoc:
      false
    end

    # Returns +true+ if the record is read only. Records loaded through joins with piggy-back
    # attributes will be marked as read only since they cannot be saved.
    def readonly?
      @readonly
    end

    # Marks this record as read only.
    def readonly!
      @readonly = true
    end

    # Returns the contents of the record as a nicely formatted string.
    def inspect
      # We check defined?(@attributes) not to issue warnings if the object is
      # allocated but not initialized.
      inspection = if defined?(@attributes) && @attributes
        self.class.attribute_names.collect do |name|
          if has_attribute?(name)
            attr = _read_attribute(name)
            value = if attr.nil?
              attr.inspect
            else
              attr = format_for_inspect(attr)
              inspection_filter.filter_param(name, attr)
            end
            "#{name}: #{value}"
          end
        end.compact.join(", ")
      else
        "not initialized"
      end

      "#<#{self.class} #{inspection}>"
    end

    # Takes a PP and prettily prints this record to it, allowing you to get a nice result from <tt>pp record</tt>
    # when pp is required.
    def pretty_print(pp)
      return super if custom_inspect_method_defined?
      pp.object_address_group(self) do
        if defined?(@attributes) && @attributes
          attr_names = self.class.attribute_names.select { |name| has_attribute?(name) }
          pp.seplist(attr_names, proc { pp.text "," }) do |attr_name|
            pp.breakable " "
            pp.group(1) do
              pp.text attr_name
              pp.text ":"
              pp.breakable
              value = _read_attribute(attr_name)
              value = inspection_filter.filter_param(attr_name, value) unless value.nil?
              pp.pp value
            end
          end
        else
          pp.breakable " "
          pp.text "not initialized"
        end
      end
    end

    # Returns a hash of the given methods with their names as keys and returned values as values.
    def slice(*methods)
      Hash[methods.flatten.map! { |method| [method, public_send(method)] }].with_indifferent_access
    end

    private

      # +Array#flatten+ will call +#to_ary+ (recursively) on each of the elements of
      # the array, and then rescues from the possible +NoMethodError+. If those elements are
      # +ActiveEntity::Base+'s, then this triggers the various +method_missing+'s that we have,
      # which significantly impacts upon performance.
      #
      # So we can avoid the +method_missing+ hit by explicitly defining +#to_ary+ as +nil+ here.
      #
      # See also https://tenderlovemaking.com/2011/06/28/til-its-ok-to-return-nil-from-to_ary.html
      def to_ary
        nil
      end

      def init_internals
        @primary_key              = self.class.primary_key
        @readonly                 = false
        @marked_for_destruction   = false

        self.class.define_attribute_methods
      end

      def initialize_internals_callback
      end

      def custom_inspect_method_defined?
        self.class.instance_method(:inspect).owner != ActiveEntity::Base.instance_method(:inspect).owner
      end

      class InspectionMask < DelegateClass(::String)
        def pretty_print(pp)
          pp.text __getobj__
        end
      end
      private_constant :InspectionMask

      def inspection_filter
        @inspection_filter ||= begin
          mask = InspectionMask.new(ActiveSupport::ParameterFilter::FILTERED)
          ActiveSupport::ParameterFilter.new(self.class.filter_attributes, mask: mask)
        end
      end
  end
end
