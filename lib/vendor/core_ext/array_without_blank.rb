# frozen_string_literal: true

class ArrayWithoutBlank < Array
  def self.new(*several_variants)
    arr = super
    arr.reject!(&:blank?)
    arr
  end

  def initialize_copy(other_ary)
    super other_ary.reject(&:blank?)
  end

  def replace(other_ary)
    super other_ary.reject(&:blank?)
  end

  def push(obj, *smth)
    return self if obj.blank?
    super
  end

  def insert(*args)
    super(*args.reject(&:blank?))
  end

  def []=(index, obj)
    return self[index] if obj.blank?
    super
  end

  def concat(other_ary)
    super other_ary.reject(&:blank?)
  end

  def +(other_ary)
    super other_ary.reject(&:blank?)
  end

  def <<(obj)
    return self if obj.blank?
    super
  end

  def to_ary
    Array.new(self)
  end
end
