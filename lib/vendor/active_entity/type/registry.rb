# frozen_string_literal: true

module ActiveEntity
  # :stopdoc:
  module Type
    class Registry # :nodoc:
      def initialize
        @registrations = []
      end

      def initialize_copy(_other)
        @registrations = @registrations.dup
      end

      def add_modifier(options, klass, **_args)
        registrations << DecorationRegistration.new(options, klass)
      end

      def register(type_name, klass = nil, **options, &block)
        unless block_given?
          block = proc { |_, *args| klass.new(*args) }
          block.ruby2_keywords if block.respond_to?(:ruby2_keywords)
        end
        registrations << Registration.new(type_name, block, **options)
      end

      def lookup(symbol, *args, **kwargs)
        registration = find_registration(symbol, *args, **kwargs)

        if registration
          registration.call(self, symbol, *args, **kwargs)
        else
          raise ArgumentError, "Unknown type #{symbol.inspect}"
        end
      end

      private

        attr_reader :registrations

        def find_registration(symbol, *args, **kwargs)
          registrations
            .select { |registration| registration.matches?(symbol, *args, **kwargs) }
            .max
        end
    end

    class Registration # :nodoc:
      def initialize(name, block, override: nil)
        @name = name
        @block = block
        @override = override
      end

      def call(_registry, *args, **kwargs)
        if kwargs.any? # https://bugs.ruby-lang.org/issues/10856
          block.call(*args, **kwargs)
        else
          block.call(*args)
        end
      end

      def matches?(type_name, *args, **kwargs)
        type_name == name
      end

      def <=>(other)
        priority <=> other.priority
      end

      protected

        attr_reader :name, :block, :override

        def priority
          override ? 1 : 0
        end
    end

    class DecorationRegistration < Registration # :nodoc:
      def initialize(options, klass, **)
        @options = options
        @klass = klass
      end

      def call(registry, *args, **kwargs)
        subtype = registry.lookup(*args, **kwargs.except(*options.keys))
        klass.new(subtype)
      end

      def matches?(*args, **kwargs)
        matches_options?(**kwargs)
      end

      def priority
        super | 4
      end

      private

        attr_reader :options, :klass

        def matches_options?(**kwargs)
          options.all? do |key, value|
            kwargs[key] == value
          end
        end
    end
  end

  # :startdoc:
end
