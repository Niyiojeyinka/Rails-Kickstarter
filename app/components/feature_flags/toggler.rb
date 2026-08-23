# frozen_string_literal: true

# Flips a feature flag on/off. Used by the ActiveAdmin Feature Flags page.
#
#   FeatureFlags::Toggler.call("new_checkout")
#   # => Result.success(true)  — flag is now enabled
#   # => Result.success(false) — flag is now disabled
class FeatureFlags::Toggler < ApplicationComponent
  def initialize(name)
    @name = name.to_s
  end

  def call
    feature = Flipper.feature(@name)
    return failure(I18n.t("components.errors.unknown_feature", name: @name)) unless feature.exist?

    FeatureFlag.enabled?(@name) ? FeatureFlag.disable(@name) : FeatureFlag.enable(@name)

    success(FeatureFlag.enabled?(@name))
  end
end
