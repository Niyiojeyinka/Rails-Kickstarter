# frozen_string_literal: true

# Feature flag declarations — add, rename, or remove flags HERE and nowhere
# else. Each entry registers the name + description and generates methods on
# FeatureFlag (see lib/feature_flag.rb):
#
#   FeatureFlag.define(:new_checkout, description: "New checkout flow")
#   FeatureFlag.new_checkout_enabled?          # generated
#   FeatureFlag.enable_new_checkout            # generated
#
# Rules:
#   - snake_case names (they become method names)
#   - the description shows up in the admin Feature Flags page
#   - config files load at boot: restart the app after editing this file
FeatureFlag.define(:new_checkout, description: "New checkout flow")
FeatureFlag.define(:dark_mode, description: "Dark theme for authenticated areas")
FeatureFlag.define(:api_v2, description: "Version 2 of the public API")
