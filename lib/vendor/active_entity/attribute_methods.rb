# frozen_string_literal: true

require "concurrent/map"
require "active_support/core_ext/enumerable"

module ActiveEntity
  module AMAttributeMethods
    extend ActiveSupport::Concern

    NAME_COMPILABLE_REGEXP = /\A[a-zA-Z_]\w*[!?=]?\z/
    CALL_COMPILABLE_REGEXP = /\A[a-zA-Z_]\w*[!?]?\z/

    included do
      class_attribute :attribute_aliases, instance_writer: false, default: {}
      class_attribute :attribute_method_matchers, instance_writer: false, default: [ ClassMethods::AttributeMethodMatcher.new ]
    end

    module ClassMethods
      # Declares a method available for all attributes with the given prefix.
      # Uses +method_missing+ and <tt>respond_to?</tt> to rewrite the method.
      #
      #   #{prefix}#{attr}(*args, &block)
      #
      # to
      #
      #   #{prefix}attribute(#{attr}, *args, &block)
      #
      # An instance method <tt>#{prefix}attribute</tt> must exist and accept
      # at least the +attr+ argument.
      #
      #   class Person
      #     include ActiveModel::AttributeMethods
      #
      #     attr_accessor :name
      #     attribute_method_prefix 'clear_'
      #     define_attribute_methods :name
      #
      #     private
      #
      #     def clear_attribute(attr)
      #       send("#{attr}=", nil)
      #     end
      #   end
      #
      #   person = Person.new
      #   person.name = 'Bob'
      #   person.name          # => "Bob"
      #   person.clear_name
      #   person.name          # => nil
      def attribute_method_prefix(*prefixes)
        self.attribute_method_matchers += prefixes.map! { |prefix| AttributeMethodMatcher.new prefix: prefix }
        undefine_attribute_methods
      end

      # Declares a method available for all attributes with the given suffix.
      # Uses +method_missing+ and <tt>respond_to?</tt> to rewrite the method.
      #
      #   #{attr}#{suffix}(*args, &block)
      #
      # to
      #
      #   attribute#{suffix}(#{attr}, *args, &block)
      #
      # An <tt>attribute#{suffix}</tt> instance method must exist and accept at
      # least the +attr+ argument.
      #
      #   class Person
      #     include ActiveModel::AttributeMethods
      #
      #     attr_accessor :name
      #     attribute_method_suffix '_short?'
      #     define_attribute_methods :name
      #
      #     private
      #
      #     def attribute_short?(attr)
      #       send(attr).length < 5
      #     end
      #   end
      #
      #   person = Person.new
      #   person.name = 'Bob'
      #   person.name          # => "Bob"
      #   person.name_short?   # => true
      def attribute_method_suffix(*suffixes)
        self.attribute_method_matchers += suffixes.map! { |suffix| AttributeMethodMatcher.new suffix: suffix }
        undefine_attribute_methods
      end

      # Declares a method available for all attributes with the given prefix
      # and suffix. Uses +method_missing+ and <tt>respond_to?</tt> to rewrite
      # the method.
      #
      #   #{prefix}#{attr}#{suffix}(*args, &block)
      #
      # to
      #
      #   #{prefix}attribute#{suffix}(#{attr}, *args, &block)
      #
      # An <tt>#{prefix}attribute#{suffix}</tt> instance method must exist and
      # accept at least the +attr+ argument.
      #
      #   class Person
      #     include ActiveModel::AttributeMethods
      #
      #     attr_accessor :name
      #     attribute_method_affix prefix: 'reset_', suffix: '_to_default!'
      #     define_attribute_methods :name
      #
      #     private
      #
      #     def reset_attribute_to_default!(attr)
      #       send("#{attr}=", 'Default Name')
      #     end
      #   end
      #
      #   person = Person.new
      #   person.name                         # => 'Gem'
      #   person.reset_name_to_default!
      #   person.name                         # => 'Default Name'
      def attribute_method_affix(*affixes)
        self.attribute_method_matchers += affixes.map! { |affix| AttributeMethodMatcher.new prefix: affix[:prefix], suffix: affix[:suffix] }
        undefine_attribute_methods
      end

      # Allows you to make aliases for attributes.
      #
      #   class Person
      #     include ActiveModel::AttributeMethods
      #
      #     attr_accessor :name
      #     attribute_method_suffix '_short?'
      #     define_attribute_methods :name
      #
      #     alias_attribute :nickname, :name
      #
      #     private
      #
      #     def attribute_short?(attr)
      #       send(attr).length < 5
      #     end
      #   end
      #
      #   person = Person.new
      #   person.name = 'Bob'
      #   person.name            # => "Bob"
      #   person.nickname        # => "Bob"
      #   person.name_short?     # => true
      #   person.nickname_short? # => true
      def alias_attribute(new_name, old_name)
        self.attribute_aliases = attribute_aliases.merge(new_name.to_s => old_name.to_s)
        CodeGenerator.batch(self, __FILE__, __LINE__) do |owner|
          attribute_method_matchers.each do |matcher|
            matcher_new = matcher.method_name(new_name).to_s
            matcher_old = matcher.method_name(old_name).to_s
            define_proxy_call false, owner, matcher_new, matcher_old
          end
        end
      end

      # Is +new_name+ an alias?
      def attribute_alias?(new_name)
        attribute_aliases.key? new_name.to_s
      end

      # Returns the original name for the alias +name+
      def attribute_alias(name)
        attribute_aliases[name.to_s]
      end

      # Declares the attributes that should be prefixed and suffixed by
      # <tt>ActiveModel::AttributeMethods</tt>.
      #
      # To use, pass attribute names (as strings or symbols). Be sure to declare
      # +define_attribute_methods+ after you define any prefix, suffix or affix
      # methods, or they will not hook in.
      #
      #   class Person
      #     include ActiveModel::AttributeMethods
      #
      #     attr_accessor :name, :age, :address
      #     attribute_method_prefix 'clear_'
      #
      #     # Call to define_attribute_methods must appear after the
      #     # attribute_method_prefix, attribute_method_suffix or
      #     # attribute_method_affix declarations.
      #     define_attribute_methods :name, :age, :address
      #
      #     private
      #
      #     def clear_attribute(attr)
      #       send("#{attr}=", nil)
      #     end
      #   end
      def define_attribute_methods(*attr_names)
        CodeGenerator.batch(generated_attribute_methods, __FILE__, __LINE__) do |owner|
          attr_names.flatten.each { |attr_name| define_attribute_method(attr_name, _owner: owner) }
        end
      end

      # Declares an attribute that should be prefixed and suffixed by
      # <tt>ActiveModel::AttributeMethods</tt>.
      #
      # To use, pass an attribute name (as string or symbol). Be sure to declare
      # +define_attribute_method+ after you define any prefix, suffix or affix
      # method, or they will not hook in.
      #
      #   class Person
      #     include ActiveModel::AttributeMethods
      #
      #     attr_accessor :name
      #     attribute_method_suffix '_short?'
      #
      #     # Call to define_attribute_method must appear after the
      #     # attribute_method_prefix, attribute_method_suffix or
      #     # attribute_method_affix declarations.
      #     define_attribute_method :name
      #
      #     private
      #
      #     def attribute_short?(attr)
      #       send(attr).length < 5
      #     end
      #   end
      #
      #   person = Person.new
      #   person.name = 'Bob'
      #   person.name        # => "Bob"
      #   person.name_short? # => true
      def define_attribute_method(attr_name, _owner: generated_attribute_methods)
        CodeGenerator.batch(_owner, __FILE__, __LINE__) do |owner|
          attribute_method_matchers.each do |matcher|
            method_name = matcher.method_name(attr_name)

            unless instance_method_already_implemented?(method_name)
              generate_method = "define_method_#{matcher.target}"

              if respond_to?(generate_method, true)
                send(generate_method, attr_name.to_s, owner: owner)
              else
                define_proxy_call true, owner, method_name, matcher.target, attr_name.to_s
              end
            end
          end
          attribute_method_matchers_cache.clear
        end
      end

      # Removes all the previously dynamically defined methods from the class.
      #
      #   class Person
      #     include ActiveModel::AttributeMethods
      #
      #     attr_accessor :name
      #     attribute_method_suffix '_short?'
      #     define_attribute_method :name
      #
      #     private
      #
      #     def attribute_short?(attr)
      #       send(attr).length < 5
      #     end
      #   end
      #
      #   person = Person.new
      #   person.name = 'Bob'
      #   person.name_short? # => true
      #
      #   Person.undefine_attribute_methods
      #
      #   person.name_short? # => NoMethodError
      def undefine_attribute_methods
        generated_attribute_methods.module_eval do
          undef_method(*instance_methods)
        end
        attribute_method_matchers_cache.clear
      end

      private
        class CodeGenerator
          class << self
            def batch(owner, path, line)
              if owner.is_a?(CodeGenerator)
                yield owner
              else
                instance = new(owner, path, line)
                result = yield instance
                instance.execute
                result
              end
            end
          end

          def initialize(owner, path, line)
            @owner = owner
            @path = path
            @line = line
            @sources = ["# frozen_string_literal: true\n"]
            @renames = {}
          end

          def <<(source_line)
            @sources << source_line
          end

          def rename_method(old_name, new_name)
            @renames[old_name] = new_name
          end

          def execute
            @owner.module_eval(@sources.join(";"), @path, @line - 1)
            @renames.each do |old_name, new_name|
              @owner.alias_method new_name, old_name
              @owner.undef_method old_name
            end
          end
        end
        private_constant :CodeGenerator

        def generated_attribute_methods
          @generated_attribute_methods ||= Module.new.tap { |mod| include mod }
        end

        def instance_method_already_implemented?(method_name)
          generated_attribute_methods.method_defined?(method_name)
        end

        # The methods +method_missing+ and +respond_to?+ of this module are
        # invoked often in a typical rails, both of which invoke the method
        # +matched_attribute_method+. The latter method iterates through an
        # array doing regular expression matches, which results in a lot of
        # object creations. Most of the time it returns a +nil+ match. As the
        # match result is always the same given a +method_name+, this cache is
        # used to alleviate the GC, which ultimately also speeds up the app
        # significantly (in our case our test suite finishes 10% faster with
        # this cache).
        def attribute_method_matchers_cache
          @attribute_method_matchers_cache ||= Concurrent::Map.new(initial_capacity: 4)
        end

        def attribute_method_matchers_matching(method_name)
          attribute_method_matchers_cache.compute_if_absent(method_name) do
            attribute_method_matchers.map { |matcher| matcher.match(method_name) }.compact
          end
        end

        # Define a method `name` in `mod` that dispatches to `send`
        # using the given `extra` args. This falls back on `define_method`
        # and `send` if the given names cannot be compiled.
        def define_proxy_call(include_private, code_generator, name, target, *extra)
          defn = if NAME_COMPILABLE_REGEXP.match?(name)
                   "def #{name}(*args)"
                 else
                   "define_method(:'#{name}') do |*args|"
                 end

          extra = (extra.map!(&:inspect) << "*args").join(", ")

          body = if CALL_COMPILABLE_REGEXP.match?(target)
                   "#{"self." unless include_private}#{target}(#{extra})"
                 else
                   "send(:'#{target}', #{extra})"
                 end

          code_generator <<
            defn <<
            body <<
            "end" <<
            "ruby2_keywords(:'#{name}') if respond_to?(:ruby2_keywords, true)"
        end

        class AttributeMethodMatcher #:nodoc:
          attr_reader :prefix, :suffix, :target

          AttributeMethodMatch = Struct.new(:target, :attr_name)

          def initialize(options = {})
            @prefix, @suffix = options.fetch(:prefix, ""), options.fetch(:suffix, "")
            @regex = /^(?:#{Regexp.escape(@prefix)})(.*)(?:#{Regexp.escape(@suffix)})$/
            @target = "#{@prefix}attribute#{@suffix}"
            @method_name = "#{prefix}%s#{suffix}"
          end

          def match(method_name)
            if @regex =~ method_name
              AttributeMethodMatch.new(target, $1)
            end
          end

          def method_name(attr_name)
            @method_name % attr_name
          end
        end
    end

    # Allows access to the object attributes, which are held in the hash
    # returned by <tt>attributes</tt>, as though they were first-class
    # methods. So a +Person+ class with a +name+ attribute can for example use
    # <tt>Person#name</tt> and <tt>Person#name=</tt> and never directly use
    # the attributes hash -- except for multiple assignments with
    # <tt>ActiveRecord::Base#attributes=</tt>.
    #
    # It's also possible to instantiate related objects, so a <tt>Client</tt>
    # class belonging to the +clients+ table with a +master_id+ foreign key
    # can instantiate master through <tt>Client#master</tt>.
    def method_missing(method, *args, &block)
      if respond_to_without_attributes?(method, true)
        super
      else
        match = matched_attribute_method(method.to_s)
        match ? attribute_missing(match, *args, &block) : super
      end
    end
    ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)

    # +attribute_missing+ is like +method_missing+, but for attributes. When
    # +method_missing+ is called we check to see if there is a matching
    # attribute method. If so, we tell +attribute_missing+ to dispatch the
    # attribute. This method can be overloaded to customize the behavior.
    def attribute_missing(match, *args, &block)
      __send__(match.target, match.attr_name, *args, &block)
    end

    # A +Person+ instance with a +name+ attribute can ask
    # <tt>person.respond_to?(:name)</tt>, <tt>person.respond_to?(:name=)</tt>,
    # and <tt>person.respond_to?(:name?)</tt> which will all return +true+.
    alias :respond_to_without_attributes? :respond_to?
    def respond_to?(method, include_private_methods = false)
      if super
        true
      elsif !include_private_methods && super(method, true)
        # If we're here then we haven't found among non-private methods
        # but found among all methods. Which means that the given method is private.
        false
      else
        !matched_attribute_method(method.to_s).nil?
      end
    end

    private
      def attribute_method?(attr_name)
        respond_to_without_attributes?(:attributes) && attributes.include?(attr_name)
      end

      # Returns a struct representing the matching attribute method.
      # The struct's attributes are prefix, base and suffix.
      def matched_attribute_method(method_name)
        matches = self.class.send(:attribute_method_matchers_matching, method_name)
        matches.detect { |match| attribute_method?(match.attr_name) }
      end

      def missing_attribute(attr_name, stack)
        raise ActiveModel::MissingAttributeError, "missing attribute: #{attr_name}", stack
      end

      def _read_attribute(attr)
        __send__(attr)
      end

      module AttrNames # :nodoc:
        DEF_SAFE_NAME = /\A[a-zA-Z_]\w*\z/

        # We want to generate the methods via module_eval rather than
        # define_method, because define_method is slower on dispatch.
        # Evaluating many similar methods may use more memory as the instruction
        # sequences are duplicated and cached (in MRI).  define_method may
        # be slower on dispatch, but if you're careful about the closure
        # created, then define_method will consume much less memory.
        #
        # But sometimes the database might return columns with
        # characters that are not allowed in normal method names (like
        # 'my_column(omg)'. So to work around this we first define with
        # the __temp__ identifier, and then use alias method to rename
        # it to what we want.
        #
        # We are also defining a constant to hold the frozen string of
        # the attribute name. Using a constant means that we do not have
        # to allocate an object on each call to the attribute method.
        # Making it frozen means that it doesn't get duped when used to
        # key the @attributes in read_attribute.
        def self.define_attribute_accessor_method(owner, attr_name, writer: false)
          method_name = "#{attr_name}#{'=' if writer}"
          if attr_name.ascii_only? && DEF_SAFE_NAME.match?(attr_name)
            yield method_name, "'#{attr_name}'"
          else
            safe_name = attr_name.unpack1("h*")
            const_name = "ATTR_#{safe_name}"
            const_set(const_name, attr_name) unless const_defined?(const_name)
            temp_method_name = "__temp__#{safe_name}#{'=' if writer}"
            attr_name_expr = "::ActiveEntity::AMAttributeMethods::AttrNames::#{const_name}"
            yield temp_method_name, attr_name_expr
            owner.rename_method(temp_method_name, method_name)
          end
        end
      end
  end

  # = Active Entity Attribute Methods
  module AttributeMethods
    extend ActiveSupport::Concern
    include AMAttributeMethods # Some AM modules will include AM::AttributeMethods, we want override it

    included do
      initialize_generated_modules
      include Read
      include Write
      include BeforeTypeCast
      include Query
      include PrimaryKey
      include TimeZoneConversion
      include Dirty
      include Serialization
    end

    RESTRICTED_CLASS_METHODS = %w(private public protected allocate new name parent superclass)

    class GeneratedAttributeMethods < Module #:nodoc:
      # mutex_m was removed from Ruby 3.4's default gems; use an internal
      # mutex instead, mirroring the fix in Rails 7.1 (rails/rails#49371)
      def initialize
        super
        @mutex = Mutex.new
      end

      def synchronize(&block)
        @mutex.synchronize(&block)
      end
    end

    class << self
      def dangerous_attribute_methods # :nodoc:
        @dangerous_attribute_methods ||= (
        Base.instance_methods +
          Base.private_instance_methods -
          Base.superclass.instance_methods -
          Base.superclass.private_instance_methods
        ).map { |m| -m.to_s }.to_set.freeze
      end
    end

    module ClassMethods
      def inherited(child_class) #:nodoc:
        child_class.initialize_generated_modules
        super
      end

      def initialize_generated_modules # :nodoc:
        @generated_attribute_methods = const_set(:GeneratedAttributeMethods, GeneratedAttributeMethods.new)
        private_constant :GeneratedAttributeMethods
        @attribute_methods_generated = false
        include @generated_attribute_methods

        super
      end

      # Generates all the attribute related methods for columns in the database
      # accessors, mutators and query methods.
      def define_attribute_methods # :nodoc:
        return false if @attribute_methods_generated
        # Use a mutex; we don't want two threads simultaneously trying to define
        # attribute methods.
        generated_attribute_methods.synchronize do
          return false if @attribute_methods_generated
          superclass.define_attribute_methods unless base_class?
          super(attribute_names)
          @attribute_methods_generated = true
        end
      end

      def undefine_attribute_methods # :nodoc:
        generated_attribute_methods.synchronize do
          super if defined?(@attribute_methods_generated) && @attribute_methods_generated
          @attribute_methods_generated = false
        end
      end

      # Raises an ActiveEntity::DangerousAttributeError exception when an
      # \Active \Record method is defined in the model, otherwise +false+.
      #
      #   class Person < ActiveEntity::Base
      #     def save
      #       'already defined by Active Entity'
      #     end
      #   end
      #
      #   Person.instance_method_already_implemented?(:save)
      #   # => ActiveEntity::DangerousAttributeError: save is defined by Active Entity. Check to make sure that you don't have an attribute or method with the same name.
      #
      #   Person.instance_method_already_implemented?(:name)
      #   # => false
      def instance_method_already_implemented?(method_name)
        if dangerous_attribute_method?(method_name)
          raise DangerousAttributeError, "#{method_name} is defined by Active Entity. Check to make sure that you don't have an attribute or method with the same name."
        end

        if superclass == Base
          super
        else
          # If ThisClass < ... < SomeSuperClass < ... < Base and SomeSuperClass
          # defines its own attribute method, then we don't want to overwrite that.
          defined = method_defined_within?(method_name, superclass, Base) &&
            ! superclass.instance_method(method_name).owner.is_a?(GeneratedAttributeMethods)
          defined || super
        end
      end

      # A method name is 'dangerous' if it is already (re)defined by Active Entity, but
      # not by any ancestors. (So 'puts' is not dangerous but 'save' is.)
      def dangerous_attribute_method?(name) # :nodoc:
        ::ActiveEntity::AttributeMethods.dangerous_attribute_methods.include?(name.to_s)
      end

      def method_defined_within?(name, klass, superklass = klass.superclass) # :nodoc:
        if klass.method_defined?(name) || klass.private_method_defined?(name)
          if superklass.method_defined?(name) || superklass.private_method_defined?(name)
            klass.instance_method(name).owner != superklass.instance_method(name).owner
          else
            true
          end
        else
          false
        end
      end

      # A class method is 'dangerous' if it is already (re)defined by Active Entity, but
      # not by any ancestors. (So 'puts' is not dangerous but 'new' is.)
      def dangerous_class_method?(method_name)
        return true if RESTRICTED_CLASS_METHODS.include?(method_name.to_s)

        if Base.respond_to?(method_name, true)
          if Object.respond_to?(method_name, true)
            Base.method(method_name).owner != Object.method(method_name).owner
          else
            true
          end
        else
          false
        end
      end

      # Returns an array of column names as strings if it's not an abstract class.
      # Otherwise it returns an empty array.
      #
      #   class Person < ActiveEntity::Base
      #   end
      #
      #   Person.attribute_names
      #   # => ["id", "created_at", "updated_at", "name", "age"]
      def attribute_names
        @attribute_names ||= if !abstract_class?
          attribute_types.keys
        else
          []
        end
      end

      # Returns true if the given attribute exists, otherwise false.
      #
      #   class Person < ActiveEntity::Base
      #   end
      #
      #   Person.has_attribute?('name')     # => true
      #   Person.has_attribute?('new_name') # => true
      #   Person.has_attribute?(:age)       # => true
      #   Person.has_attribute?(:nothing)   # => false
      def has_attribute?(attr_name)
        attr_name = attr_name.to_s
        attr_name = attribute_aliases[attr_name] || attr_name
        attribute_types.key?(attr_name)
      end

      def _has_attribute?(attr_name) # :nodoc:
        attribute_types.key?(attr_name)
      end

      # https://github.com/rails/rails/blob/df475877efdcf74d7524f734ab8ad1d4704fd187/activemodel/lib/active_model/attribute_methods.rb#L208-L217
      def alias_attribute(new_name, old_name)
        self.attribute_aliases = attribute_aliases.merge(new_name.to_s => old_name.to_s)
        CodeGenerator.batch(self, __FILE__, __LINE__) do |owner|
          attribute_method_matchers.each do |matcher|
            matcher_new = matcher.method_name(new_name).to_s
            matcher_old = matcher.method_name(old_name).to_s
            define_proxy_call false, owner, matcher_new, matcher_old
          end
        end
      end
    end

    # Returns +true+ if the given attribute is in the attributes hash, otherwise +false+.
    #
    #   class Person < ActiveEntity::Base
    #     alias_attribute :new_name, :name
    #   end
    #
    #   person = Person.new
    #   person.has_attribute?(:name)     # => true
    #   person.has_attribute?(:new_name) # => true
    #   person.has_attribute?('age')     # => true
    #   person.has_attribute?(:nothing)  # => false
    def has_attribute?(attr_name)
      attr_name = attr_name.to_s
      attr_name = self.class.attribute_aliases[attr_name] || attr_name
      @attributes.key?(attr_name)
    end

    def _has_attribute?(attr_name) # :nodoc:
      @attributes.key?(attr_name)
    end

    # Returns an array of names for the attributes available on this object.
    #
    #   class Person < ActiveEntity::Base
    #   end
    #
    #   person = Person.new
    #   person.attribute_names
    #   # => ["id", "created_at", "updated_at", "name", "age"]
    def attribute_names
      @attributes.keys
    end

    # Returns a hash of all the attributes with their names as keys and the values of the attributes as values.
    #
    #   class Person < ActiveEntity::Base
    #   end
    #
    #   person = Person.create(name: 'Francesco', age: 22)
    #   person.attributes
    #   # => {"id"=>3, "created_at"=>Sun, 21 Oct 2012 04:53:04, "updated_at"=>Sun, 21 Oct 2012 04:53:04, "name"=>"Francesco", "age"=>22}
    def attributes
      @attributes.to_hash
    end

    # Returns an <tt>#inspect</tt>-like string for the value of the
    # attribute +attr_name+. String attributes are truncated up to 50
    # characters, Date and Time attributes are returned in the
    # <tt>:db</tt> format. Other attributes return the value of
    # <tt>#inspect</tt> without modification.
    #
    #   person = Person.create!(name: 'David Heinemeier Hansson ' * 3)
    #
    #   person.attribute_for_inspect(:name)
    #   # => "\"David Heinemeier Hansson David Heinemeier Hansson ...\""
    #
    #   person.attribute_for_inspect(:created_at)
    #   # => "\"2012-10-22 00:15:07\""
    #
    #   person.attribute_for_inspect(:tag_ids)
    #   # => "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]"
    def attribute_for_inspect(attr_name)
      attr_name = attr_name.to_s
      value = _read_attribute(attr_name)
      format_for_inspect(value)
    end

    # Returns +true+ if the specified +attribute+ has been set by the user or by a
    # database load and is neither +nil+ nor <tt>empty?</tt> (the latter only applies
    # to objects that respond to <tt>empty?</tt>, most notably Strings). Otherwise, +false+.
    # Note that it always returns +true+ with boolean attributes.
    #
    #   class Task < ActiveEntity::Base
    #   end
    #
    #   task = Task.new(title: '', is_done: false)
    #   task.attribute_present?(:title)   # => false
    #   task.attribute_present?(:is_done) # => true
    #   task.title = 'Buy milk'
    #   task.is_done = true
    #   task.attribute_present?(:title)   # => true
    #   task.attribute_present?(:is_done) # => true
    def attribute_present?(attr_name)
      attr_name = attr_name.to_s
      value = _read_attribute(attr_name)
      !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
    end

    # Returns the value of the attribute identified by <tt>attr_name</tt> after it has been typecast (for example,
    # "2004-12-12" in a date column is cast to a date object, like Date.new(2004, 12, 12)). It raises
    # <tt>ActiveModel::MissingAttributeError</tt> if the identified attribute is missing.
    #
    # Note: +:id+ is always present.
    #
    #   class Person < ActiveEntity::Base
    #     belongs_to :organization
    #   end
    #
    #   person = Person.new(name: 'Francesco', age: '22')
    #   person[:name] # => "Francesco"
    #   person[:age]  # => 22
    #
    #   person = Person.select('id').first
    #   person[:name]            # => ActiveModel::MissingAttributeError: missing attribute: name
    #   person[:organization_id] # => ActiveModel::MissingAttributeError: missing attribute: organization_id
    def [](attr_name)
      read_attribute(attr_name) { |n| missing_attribute(n, caller) }
    end

    # Updates the attribute identified by <tt>attr_name</tt> with the specified +value+.
    # (Alias for the protected #write_attribute method).
    #
    #   class Person < ActiveEntity::Base
    #   end
    #
    #   person = Person.new
    #   person[:age] = '22'
    #   person[:age] # => 22
    #   person[:age].class # => Integer
    def []=(attr_name, value)
      write_attribute(attr_name, value)
    end

    private

      def attribute_method?(attr_name)
        # We check defined? because Syck calls respond_to? before actually calling initialize.
        defined?(@attributes) && @attributes.key?(attr_name)
      end

      def format_for_inspect(value)
        if value.is_a?(String) && value.length > 50
          "#{value[0, 50]}...".inspect
        elsif value.is_a?(Date) || value.is_a?(Time)
          %("#{value.to_s(:db)}")
        else
          value.inspect
        end
      end

      def pk_attribute?(name)
        name == @primary_key
      end
  end
end
