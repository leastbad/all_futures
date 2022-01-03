# frozen_string_literal: true

module AllFutures
  class RecordNotFound < StandardError; end

  module Finder
    extend ActiveSupport::Concern

    module ClassMethods
      def all
        Kredis.redis.scan_each(match: "#{name}:*").map { |key| find(key.delete_prefix("#{name}:")) }
      end

      def any?
        all.any?
      end

      def exists?(id)
        return all.any? unless id
        return false if id == false
        [Hash, Array].include?(id.class) ? where(id).any? : Kredis.redis.exists?("#{name}:#{id}")
      end

      def find(*ids)
        raise ActiveRecord::RecordNotFound.new("Couldn't find #{name} without an id") unless ids.flatten.present?
        if ids.size == 1 && [String, Integer, Symbol].include?(ids.first.class)
          record = load_model(ids.first)
          model = new record["attributes"].merge(id: ids.first)
          load_versions(model, record)
          set_previous_attributes(model, record)
          model.instance_variable_set "@created_at", Time.zone.parse(record["created_at"])
          model.instance_variable_set "@updated_at", Time.zone.parse(record["updated_at"])
          model
        else
          results = ids.flatten.map do |id|
            find(id)
          rescue AllFutures::RecordNotFound
            nil
          end
          return results if results.size == results.compact.size
          raise AllFutures::RecordNotFound.new("Couldn't find all #{name.pluralize} with ids: #{ids.flatten.join(", ")} (found #{results.compact.size} results, but was looking for #{results.size})")
        end
      end

      def find_by
      end

      def where
      end
    end
  end
end
