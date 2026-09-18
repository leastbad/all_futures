# frozen_string_literal: true

# ruby -Ilib examples/code/versioned_draft.rb
# Requires Redis on localhost (Kredis db 1 via the gem test configurator pattern).

require "logger"
require "bundler/setup"
require "all_futures"

Time.zone = "UTC"
Kredis.configurator = Class.new {
  def config_for(*) = {db: "1"}
  def root = Pathname.new(Dir.pwd)
}.new

class Draft < AllFutures::Base
  enable_versioning!
  attribute :title, :string
  attribute :body, :string
end

draft = Draft.create(title: "v1", body: "once")
draft.update(body: "twice")
puts "version=#{draft.current_version} body=#{Draft.find(draft.id).body}"
puts "v1 body=#{draft.version(1).attributes["body"]}"
