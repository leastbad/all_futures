# frozen_string_literal: true

require "test_helper"

# rubocop:disable Lint/ConstantDefinitionInBlock:
describe AllFutures::Callbacks do
  # save callbacks

  it "basic before_save works" do
    class BeforeSaveCallback < AllFutures::Base
      before_save :init_counter

      private

      def init_counter
        @count = 5
      end
    end

    future = BeforeSaveCallback.new
    future.save
    assert_equal 5, future.instance_variable_get("@count")
  end

  it "before_save with block works" do
    class BeforeSaveBlockCallback < AllFutures::Base
      before_save do
        @count = 10
      end
    end

    future = BeforeSaveBlockCallback.new
    future.save
    assert_equal 10, future.instance_variable_get("@count")
  end

  it "basic after_save works" do
    class AfterSaveCallback < AllFutures::Base
      after_save :init_counter

      private

      def init_counter
        @count = 15
      end
    end

    future = AfterSaveCallback.new
    future.save
    assert_equal 15, future.instance_variable_get("@count")
  end

  it "after_save with block works" do
    class AfterSaveBlockCallback < AllFutures::Base
      after_save do
        @count = 20
      end
    end

    future = AfterSaveBlockCallback.new
    future.save
    assert_equal 20, future.instance_variable_get("@count")
  end

#   # update callbacks

  it "basic before_update works" do
    class BeforeUpdateCallback < AllFutures::Base
      attribute :foo, :boolean
      before_update :init_counter

      private

      def init_counter
        @count = 25
      end
    end

    future = BeforeUpdateCallback.new
    future.update foo: true
    assert_equal 25, future.instance_variable_get("@count")
  end

  it "before_update with block works" do
    class BeforeUpdateBlockCallback < AllFutures::Base
      attribute :foo, :boolean

      before_update do
        @count = 30
      end
    end

    future = BeforeUpdateBlockCallback.new
    future.update foo: true
    assert_equal 30, future.instance_variable_get("@count")
  end

  it "basic after_update works" do
    class AfterUpdateCallback < AllFutures::Base
      attribute :foo, :boolean
      after_update :init_counter

      private

      def init_counter
        @count = 35
      end
    end

    future = AfterUpdateCallback.new
    future.update foo: true
    assert_equal 35, future.instance_variable_get("@count")
  end

  it "after_update with block works" do
    class AfterUpdateBlockCallback < AllFutures::Base
      attribute :foo, :boolean

      after_update do
        @count = 40
      end
    end

    future = AfterUpdateBlockCallback.new
    future.update foo: true
    assert_equal 40, future.instance_variable_get("@count")
  end

#   # destroy callbacks

  it "basic before_destroy works" do
    class BeforeDestroyCallback < AllFutures::Base
      before_destroy :init_counter

      private

      def init_counter
        @count = 45
      end
    end

    future = BeforeDestroyCallback.new
    future.destroy
    assert_equal 45, future.instance_variable_get("@count")
  end

  it "before_destroy with block works" do
    class BeforeDestroyBlockCallback < AllFutures::Base
      before_destroy do
        @count = 50
      end
    end

    future = BeforeDestroyBlockCallback.new
    future.destroy
    assert_equal 50, future.instance_variable_get("@count")
  end

  it "basic after_destroy works" do
    class AfterDestroyCallback < AllFutures::Base
      after_destroy :init_counter

      private

      def init_counter
        @count = 55
      end
    end

    future = AfterDestroyCallback.new
    future.destroy
    assert_equal 55, future.instance_variable_get("@count")
  end

  it "after_destroy with block works" do
    class AfterDestroyBlockCallback < AllFutures::Base
      after_destroy do
        @count = 60
      end
    end

    future = AfterDestroyBlockCallback.new
    future.destroy
    assert_equal 60, future.instance_variable_get("@count")
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock:
