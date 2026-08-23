# frozen_string_literal: true

require "feature_flag"
require Rails.root.join("config/flags")

# Feature flags, ActiveRecord-backed (tables: flipper_features, flipper_gates).
#
# Use the FeatureFlag facade (lib/feature_flag.rb) — it owns flag-name
# constants and the gate helpers:
#
#   FeatureFlag.enabled?(:new_checkout)             # global
#   FeatureFlag.on?(:new_checkout, actor: user)     # per actor (any model)
#   FeatureFlag.enable_segment(:new_checkout, :admins)
#   FeatureFlag.enable_percentage(:new_checkout, 25)
#
# Manage flags in the admin panel (/admin/feature_flags and /admin/flipper).
Flipper.configure do |config|
  config.default do
    adapter = Flipper::Adapters::ActiveRecord.new

    # Layer Rails.cache (Solid Cache in production, memory store in dev) over
    # the ActiveRecord adapter. write_through refreshes the cache on every
    # change, so toggles are visible across all processes immediately;
    # FLIPPER_CACHE_TTL (seconds) is the safety net for out-of-band edits.
    cached_adapter = Flipper::Adapters::ActiveSupportCacheStore.new(
      adapter,
      Rails.cache,
      ENV.fetch("FLIPPER_CACHE_TTL", 60).to_i,
      write_through: true,
      race_condition_ttl: 5.seconds
    )

    Flipper.new(cached_adapter)
  end
end

# ---- Segments (Flipper groups) ----
# A segment is a named actor rule; enable a flag for a whole segment with
# FeatureFlag.enable_segment(:flag, :segment_name). The block receives the
# RAW actor object (FeatureFlag.define_segment unwraps Flipper's internal
# wrapper, so is_a?/class checks work). Any model can be an actor
# (ApplicationRecord includes Flipper::Identifier), as can any object that
# responds to #flipper_id.
FeatureFlag.define_segment(:admins) do |actor|
  actor.is_a?(AdminUser)
end

FeatureFlag.define_segment(:persisted_records) do |actor|
  actor.respond_to?(:persisted?) && actor.persisted?
end
