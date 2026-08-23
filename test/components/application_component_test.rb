# frozen_string_literal: true

require "test_helper"

class ApplicationComponentTest < ActiveSupport::TestCase
  class PingComponent < ApplicationComponent
    def call = success("pong")
  end

  test ".call instantiates and invokes #call" do
    result = PingComponent.call

    assert_predicate result, :success?
    assert_equal "pong", result.value
  end

  test "#call raises NotImplementedError on the base class" do
    assert_raises(NotImplementedError) { ApplicationComponent.call }
  end
end
