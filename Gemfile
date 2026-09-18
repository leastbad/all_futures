# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in all_futures.gemspec
gemspec

# Local fork of the abandoned activeentity gem, patched for modern Rails
gem "activeentity", path: "../activeentity"

# connection_pool 3.x uses anonymous kwrest forwarding in blocks, which Ruby 3.3.0 can't parse
# TODO: remove once local Ruby is >= 3.4
gem "connection_pool", "< 3"
