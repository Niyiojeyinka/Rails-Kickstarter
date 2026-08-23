# frozen_string_literal: true

require "test_helper"

class FeatureFlagTest < ActiveSupport::TestCase
  TEST_FLAG = :feature_flag_test_flag

  teardown do
    [ TEST_FLAG, :new_checkout ].each do |name|
      Flipper.feature(name).remove if Flipper.feature(name).exist?
    end
  end

  test "define declares name and description in one place" do
    assert_equal "New checkout flow", FeatureFlag.description(:new_checkout)
    assert_equal "Version 2 of the public API", FeatureFlag.description(:api_v2)
    assert FeatureFlag.registered?(:new_checkout)
    assert_not FeatureFlag.registered?(:unknown_flag)
  end

  test "define generates a per-flag predicate and enable/disable methods" do
    assert_respond_to FeatureFlag, :new_checkout_enabled?
    assert_respond_to FeatureFlag, :enable_new_checkout
    assert_respond_to FeatureFlag, :disable_new_checkout

    FeatureFlag.enable_new_checkout
    assert FeatureFlag.new_checkout_enabled?

    FeatureFlag.disable_new_checkout
    assert_not FeatureFlag.new_checkout_enabled?
  end

  test "generated predicate accepts an actor" do
    admin_user = admin_users(:one)
    other = admin_users(:two)

    FeatureFlag.enable_for(:new_checkout, admin_user)

    assert FeatureFlag.new_checkout_enabled?(admin_user)
    assert_not FeatureFlag.new_checkout_enabled?(other)
    assert_not FeatureFlag.new_checkout_enabled?
  end

  test "generic helpers enable and disable globally" do
    FeatureFlag.enable(TEST_FLAG)
    assert FeatureFlag.enabled?(TEST_FLAG)

    FeatureFlag.disable(TEST_FLAG)
    assert_not FeatureFlag.enabled?(TEST_FLAG)
  end

  test "gates per actor — any model with a flipper_id" do
    admin_user = admin_users(:one)
    other = admin_users(:two)

    FeatureFlag.enable_for(TEST_FLAG, admin_user)

    assert FeatureFlag.enabled_for?(TEST_FLAG, admin_user)
    assert FeatureFlag.on?(TEST_FLAG, actor: admin_user)
    assert_not FeatureFlag.on?(TEST_FLAG, actor: other)
    # Actor gating does not turn the flag on globally
    assert_not FeatureFlag.enabled?(TEST_FLAG)
  end

  test "gates per actor — plain objects that respond to flipper_id work too" do
    actor = Struct.new(:flipper_id).new("poro-1")

    FeatureFlag.enable_for(TEST_FLAG, actor)
    assert FeatureFlag.enabled_for?(TEST_FLAG, actor)

    FeatureFlag.disable_for(TEST_FLAG, actor)
    assert_not FeatureFlag.enabled_for?(TEST_FLAG, actor)
  end

  test "gates per segment" do
    FeatureFlag.define_segment(:flag_test_admins) { |actor| actor.is_a?(AdminUser) }
    FeatureFlag.enable_segment(TEST_FLAG, :flag_test_admins)

    assert FeatureFlag.on?(TEST_FLAG, actor: admin_users(:one))
    assert_not FeatureFlag.on?(TEST_FLAG, actor: Struct.new(:flipper_id).new("poro-1"))
  end

  test "gates by percentage of actors" do
    FeatureFlag.enable_percentage(TEST_FLAG, 100)
    assert FeatureFlag.on?(TEST_FLAG, actor: admin_users(:one))

    FeatureFlag.enable_percentage(TEST_FLAG, 0)
    assert_not FeatureFlag.on?(TEST_FLAG, actor: admin_users(:one))
  end
end
