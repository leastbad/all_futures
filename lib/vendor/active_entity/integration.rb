# frozen_string_literal: true

require "active_support/core_ext/string/filters"

module ActiveEntity
  module Integration
    extend ActiveSupport::Concern

    # Returns a +String+, which Action Pack uses for constructing a URL to this
    # object. The default implementation returns this record's id as a +String+,
    # or +nil+ if this record's unsaved.
    #
    # For example, suppose that you have a User model, and that you have a
    # <tt>resources :users</tt> route. Normally, +user_path+ will
    # construct a path with the user object's 'id' in it:
    #
    #   user = User.find_by(name: 'Phusion')
    #   user_path(user)  # => "/users/1"
    #
    # You can override +to_param+ in your model to make +user_path+ construct
    # a path using the user's name instead of the user's id:
    #
    #   class User < ActiveEntity::Base
    #     def to_param  # overridden
    #       name
    #     end
    #   end
    #
    #   user = User.find_by(name: 'Phusion')
    #   user_path(user)  # => "/users/Phusion"
    def to_param
      # We can't use alias_method here, because method 'id' optimizes itself on the fly.
      id&.to_s # Be sure to stringify the id for routes
    end

    module ClassMethods
      # Defines your model's +to_param+ method to generate "pretty" URLs
      # using +method_name+, which can be any attribute or method that
      # responds to +to_s+.
      #
      #   class User < ActiveEntity::Base
      #     to_param :name
      #   end
      #
      #   user = User.find_by(name: 'Fancy Pants')
      #   user.id         # => 123
      #   user_path(user) # => "/users/123-fancy-pants"
      #
      # Values longer than 20 characters will be truncated. The value
      # is truncated word by word.
      #
      #   user = User.find_by(name: 'David Heinemeier Hansson')
      #   user.id         # => 125
      #   user_path(user) # => "/users/125-david-heinemeier"
      #
      # Because the generated param begins with the record's +id+, it is
      # suitable for passing to +find+. In a controller, for example:
      #
      #   params[:id]               # => "123-fancy-pants"
      #   User.find(params[:id]).id # => 123
      def to_param(method_name = nil)
        if method_name.nil?
          super()
        else
          define_method :to_param do
            if (default = super()) &&
                 (result = send(method_name).to_s).present? &&
                   (param = result.squish.parameterize.truncate(20, separator: /-/, omission: "")).present?
              "#{default}-#{param}"
            else
              default
            end
          end
        end
      end
    end
  end
end
