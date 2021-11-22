# frozen_string_literal: true

require File.expand_path("../lib/all_futures/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name = "all_futures"
  gem.license = "MIT"
  gem.version = AllFutures::VERSION
  gem.authors = ["leastbad"]
  gem.email = ["hello@leastbad.com"]
  gem.homepage = "https://allfutures.leastbad.com/"
  gem.summary = "A Redis-backed virtual ActiveModel, full of possibilities."
  gem.metadata = {
    "source_code_uri" => "https://github.com/leastbad/all_futures",
    "documentation_uri" => "https://allfutures.leastbad.com/"
  }

  gem.files = Dir["lib/**/*.rb", "bin/*", "[A-Z]*"]

  gem.add_dependency "kredis", "~> 1.0"
  gem.add_dependency "activeentity", "~> 6.1"
  gem.add_dependency "activemodel", ">= 4.0"
  gem.add_dependency "activesupport", ">= 4.0"
  gem.add_dependency "activerecord", ">= 4.0"

  gem.add_development_dependency "activerecord", ">= 4.0"
  gem.add_development_dependency "magic_frozen_string_literal", "~> 1.2.0"
  gem.add_development_dependency "railties", ">= 4.0"
  gem.add_development_dependency "rake", "~> 13.0", ">= 13.0.3"
  gem.add_development_dependency "ruby_jard", "~> 0.3"
  gem.add_development_dependency "standardrb", "~> 1.0"
end
