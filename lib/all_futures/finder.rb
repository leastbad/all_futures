# frozen_string_literal: true

module AllFutures
  class RecordNotFound < StandardError; end

  class InvalidAttribute < StandardError; end

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
        raise AllFutures::RecordNotFound.new("Couldn't find #{name} without an id") unless ids.flatten.present?
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

      def find_by(attrs = {})
        result = where(attrs)
        result.any? ? result.first : nil
      end

      def find_by!(attrs = {})
        result = find_by(attrs)
        result.present? ? result : raise(AllFutures::RecordNotFound.new("Couldn't find #{name} with #{_pretty_attrs(attrs)}"))
      end

      def valid_attribute?(attribute)
        (attribute_names + ["id"]).include?(attribute.to_s)
      end

      def where(attrs = {})
        return all if attrs.blank?
        attrs.each_key { |key| raise AllFutures::InvalidAttribute.new("#{key} is not a valid attribute") unless valid_attribute?(key) }
        return find(attrs.values.first) if attrs.one? && attrs.keys.first == :id
        all.select do |record|
          attrs.all? { |(attribute, value)| record.send(attribute) == value.to_s }
        end
      end

      private

      def _pretty_attrs(attrs)
        attrs.map { |key, value| "#{key}: #{value}" }.join(", ")
      end
    end
  end
end
