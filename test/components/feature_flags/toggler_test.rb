# frozen_string_literal: true

require "test_helper"

class FeatureFlags::TogglerTest < ActiveSupport::TestCase
  teardown do
    Flipper.disable(:sample_toggle) if Flipper.feature(:sample_toggle).exist?
  end

  test "enables a disabled feature" do
    Flipper.disable(:sample_toggle)

    result = FeatureFlags::Toggler.call(:sample_toggle)

    assert_predicate result, :success?
    assert_equal true, result.value
    assert Flipper.enabled?(:sample_toggle)
  end

  test "disables an enabled feature" do
    Flipper.enable(:sample_toggle)

    result = FeatureFlags::Toggler.call(:sample_toggle)

    assert_predicate result, :success?
    assert_equal false, result.value
    assert_not Flipper.enabled?(:sample_toggle)
  end

  test "fails for a feature that was never registered" do
    result = FeatureFlags::Toggler.call(:never_registered_flag)

    assert_predicate result, :failure?
    assert_equal "Unknown feature: never_registered_flag", result.error
  end
end
