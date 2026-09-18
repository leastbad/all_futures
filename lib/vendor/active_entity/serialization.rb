# frozen_string_literal: true

module ActiveEntity #:nodoc:
  # = Active Entity \Serialization
  module Serialization
    extend ActiveSupport::Concern
    include ActiveModel::Serializers::JSON

    included do
      self.include_root_in_json = false
    end

    def serializable_hash(options = nil)
      options = options ? options.dup : {}

      include_embeds = options.delete :include_embeds
      if include_embeds
        includes = Array.wrap(options[:include]).concat(self.class.embeds_association_names)
        options[:include] ||= []
        options[:include].concat includes
      end

      options[:except] = Array(options[:except]).map(&:to_s)

      super(options)
    end
  end
end
