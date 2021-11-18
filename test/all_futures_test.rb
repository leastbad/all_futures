# frozen_string_literal: true

require "test_helper"

class ExampleModel < AllFutures::Base
	attribute :name, :string
	attribute :age, :integer, default: 21
end

class TestAllFutures < Minitest::Test
	def test_that_it_has_a_version_number
		refute_nil ::AllFutures::VERSION
	end
	
	def test_example_model_can_be_initialized
		assert ExampleModel.new
	end
end
