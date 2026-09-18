# frozen_string_literal: true

#--
# Copyright (c) 2004-2020 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require "active_support"
require "active_support/rails"
require "active_model"
require "yaml"

require "core_ext/array_without_blank"

require "active_entity/version"
require "active_model/attribute_set"
require "active_entity/errors"

module ActiveEntity
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Callbacks
  autoload :Core
  autoload :Enum
  autoload :Inheritance
  autoload :Integration
  autoload :ModelSchema
  autoload :NestedAttributes
  autoload :Persistence
  autoload :ReadonlyAttributes
  autoload :Reflection
  autoload :Serialization
  autoload :Store
  autoload :Translation
  autoload :Validations

  eager_autoload do
    autoload :Aggregations
    autoload :Associations
    autoload :AttributeAssignment
    autoload :AttributeMethods
    autoload :ValidateEmbedsAssociation

    autoload :Type
  end

  module Coders
    autoload :YAMLColumn, "active_entity/coders/yaml_column"
    autoload :JSON, "active_entity/coders/json"
  end

  module AttributeMethods
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :BeforeTypeCast
      autoload :Dirty
      autoload :PrimaryKey
      autoload :Query
      autoload :Read
      autoload :TimeZoneConversion
      autoload :Write
      autoload :Serialization
    end
  end

  def self.eager_load!
    super

    ActiveEntity::Associations.eager_load!
    ActiveEntity::AttributeMethods.eager_load!
  end
end

ActiveSupport.on_load(:i18n) do
  I18n.load_path << File.expand_path("active_entity/locale/en.yml", __dir__)
end

YAML.load_tags["!ruby/object:ActiveEntity::AttributeSet"] = "ActiveModel::AttributeSet"
YAML.load_tags["!ruby/object:ActiveEntity::LazyAttributeHash"] = "ActiveModel::LazyAttributeHash"
