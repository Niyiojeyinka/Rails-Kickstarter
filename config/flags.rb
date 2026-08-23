# frozen_string_literal: true

# Feature flag declarations — add, rename, or remove flags HERE and nowhere
# else. Each entry registers the name + description and generates methods on
# FeatureFlag (see lib/feature_flag.rb):
#
#   FeatureFlag.define(:new_checkout, description: :"feature_flags.descriptions.new_checkout")
#   FeatureFlag.new_checkout_enabled?          # generated
#   FeatureFlag.enable_new_checkout            # generated
#
# Rules:
#   - snake_case names (they become method names)
#   - the description shows up in the admin Feature Flags page
#   - config files load at boot: restart the app after editing this file
FeatureFlag.define(:new_checkout, description: :"feature_flags.descriptions.new_checkout")
FeatureFlag.define(:dark_mode, description: :"feature_flags.descriptions.dark_mode")
FeatureFlag.define(:api_v2, description: :"feature_flags.descriptions.api_v2")
