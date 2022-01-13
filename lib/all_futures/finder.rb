# frozen_string_literal: true

module AllFutures
  module Finder
    extend ActiveSupport::Concern

    module ClassMethods
      def all
        Kredis.redis.scan_each(match: "#{name}:*").map do |key|
          find(key.delete_prefix("#{name}:"))
        end.sort_by(&:created_at)
      end

      def any?(&block)
        block ? all.any?(&block) : all.any?
      end

      def count
        Kredis.redis.keys("#{name}:*").size
      end

      def exists?(id)
        return all.any? unless id
        return false if id == false
        [Hash, Array].include?(id.class) ? where(id).any? : Kredis.redis.exists?("#{name}:#{id}")
      end

      def fifth
        find_nth 4
      end

      def fifth!
        fifth || raise(AllFutures::RecordNotFound.new("Couldn't find #{name} record"))
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

      def find_or_create_by(attrs = {}, &block)
        return create({}, &block) unless attrs.present?
        find_by!(attrs)
      rescue AllFutures::RecordNotFound
        create(attrs, &block)
      end

      def find_or_initialize_by(attrs = {}, &block)
        return new({}, &block) unless attrs.present?
        find_by!(attrs)
      rescue AllFutures::RecordNotFound
        new(attrs, &block)
      end

      def find_sole_by(attrs = {}, &block)
        found, undesired = where(attrs, &block).first(2)

        if found.nil?
          raise AllFutures::RecordNotFound.new("Couldn't find #{name} record")
        elsif undesired.present?
          raise AllFutures::SoleRecordExceeded.new("Found multiple #{name} records when expecting only one")
        else
          found
        end
      end

      def first(limit = nil)
        limit ? all.first(limit) : all.first
      end

      def first!
        first || raise(AllFutures::RecordNotFound.new("Couldn't find #{name} record"))
      end

      def forty_two
        find_nth 41
      end

      def forty_two!
        forty_two || raise(AllFutures::RecordNotFound.new("Couldn't find #{name} record"))
      end

      def fourth
        find_nth 3
      end

      def fourth!
        fourth || raise(AllFutures::RecordNotFound.new("Couldn't find #{name} record"))
      end

      def ids
        Kredis.redis.keys("#{name}:*").map { |id| id.delete_prefix("#{name}:") }
      end

      def include?(record)
        record.is_a?(self) && exists?(record.id)
      end
      alias_method :member?, :include?

      def last(limit = nil)
        limit ? all.last(limit) : all.last
      end

      def last!
        last || raise(AllFutures::RecordNotFound.new("Couldn't find #{name} record"))
      end

      def second
        find_nth 1
      end

      def second!
        second || raise(AllFutures::RecordNotFound.new("Couldn't find #{name} record"))
      end

      def second_to_last
        find_nth_from_last 1
      end

      def second_to_last!
        second_to_last || raise(AllFutures::RecordNotFound.new("Couldn't find #{name} record"))
      end

      def sole
        found, undesired = first(2)

        if found.nil?
          raise AllFutures::RecordNotFound.new("Couldn't find #{name} record")
        elsif undesired.present?
          raise AllFutures::SoleRecordExceeded.new("Found multiple #{name} records when expecting only one")
        else
          found
        end
      end

      def third
        find_nth 2
      end

      def third!
        third || raise(AllFutures::RecordNotFound.new("Couldn't find #{name} record"))
      end

      def third_to_last
        find_nth_from_last 2
      end

      def third_to_last!
        third_to_last || raise(AllFutures::RecordNotFound.new("Couldn't find #{name} record"))
      end

      def where(attrs = {}, &block)
        if block.blank?
          return all if attrs.blank?
          begin
            return [find(attrs.values.first)] if attrs.one? && attrs.keys.first == :id
          rescue AllFutures::RecordNotFound
            return []
          end
        end

        attrs.each_key { |key| raise AllFutures::InvalidAttribute.new("#{key} is not a valid attribute") unless valid_attribute?(key) }
        all.select do |record|
          attrs.all? do |(attribute, value)|
            record.send(attribute) == value.to_s
          end && (block ? block.call(record) : true)
        end
      end

      private

      def find_nth(index)
        records = all
        records.size >= index ? records[index] : nil
      end

      def find_nth_from_last(index)
        records = all.reverse
        records.size >= index ? records[index] : nil
      end

      def _pretty_attrs(attrs)
        attrs.map { |key, value| "#{key}: #{value}" }.join(", ")
      end
    end
  end
end
