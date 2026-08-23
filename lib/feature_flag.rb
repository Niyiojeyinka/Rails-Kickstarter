# frozen_string_literal: true

# Facade over Flipper — the single place that knows how feature flags are
# declared, checked, and gated.
#
# Flags are declared ONCE in config/flags.rb:
#
#   FeatureFlag.define(:new_checkout, description: :"feature_flags.descriptions.new_checkout")
#
# Each declaration generates convenience methods on this module:
#
#   FeatureFlag.new_checkout_enabled?          # on globally?
#   FeatureFlag.new_checkout_enabled?(user)    # on for this actor?
#   FeatureFlag.enable_new_checkout
#   FeatureFlag.disable_new_checkout
#
# For dynamic flag names (e.g. iterating Flipper.features), the generic
# helpers cover every gate:
#
#   FeatureFlag.enabled?(:new_checkout)
#   FeatureFlag.enable_for(:new_checkout, user)          # any model / object with #flipper_id
#   FeatureFlag.enable_segment(:new_checkout, :admins)
#   FeatureFlag.enable_percentage(:new_checkout, 25)
#
# Flag names must be valid Ruby method names (snake_case) because each one
# becomes a generated method. Any ActiveRecord model can be an actor
# (ApplicationRecord includes Flipper::Identifier). Segments are named actor
# rules defined with define_segment — see config/initializers/flipper.rb.
module FeatureFlag
  class << self
    # -- Registry --

    # name => description. Populated by FeatureFlag.define in config/flags.rb
    # (the single declaration point; the admin Feature Flags page reads it).
    def registry
      @registry ||= {}
    end

    # Declares a flag and generates its methods:
    #   <name>_enabled?(actor = nil), enable_<name>, disable_<name>
    def define(name, description:)
      name = name.to_sym
      registry[name] = description

      define_singleton_method(:"#{name}_enabled?") do |actor = nil|
        actor ? Flipper.enabled?(name, actor) : Flipper.enabled?(name)
      end

      define_singleton_method(:"enable_#{name}") { Flipper.enable(name) }
      define_singleton_method(:"disable_#{name}") { Flipper.disable(name) }
    end

    def description(name)
      description = registry[name.to_sym]
      description && I18n.t(description)
    end

    def registered?(name)
      registry.key?(name.to_sym)
    end

    # -- Global gate --

    def enabled?(name)
      Flipper.enabled?(name)
    end

    def enable(name)
      Flipper.enable(name)
    end

    def disable(name)
      Flipper.disable(name)
    end

    # -- Actor gate (any model / object with a #flipper_id) --

    def enabled_for?(name, actor)
      Flipper.enabled?(name, actor)
    end

    def enable_for(name, actor)
      Flipper.enable(name, actor)
    end

    def disable_for(name, actor)
      Flipper.disable(name, actor)
    end

    # On for this actor, or globally?
    def on?(name, actor: nil)
      actor ? Flipper.enabled?(name, actor) : Flipper.enabled?(name)
    end

    # -- Segment (group) gate --

    def enable_segment(name, segment)
      Flipper.enable_group(name, segment)
    end

    def disable_segment(name, segment)
      Flipper.disable_group(name, segment)
    end

    # -- Percentage gate --

    def enable_percentage(name, percent)
      Flipper.enable_percentage_of_actors(name, percent)
    end

    # Registers a segment as an actor rule. The block receives the RAW actor
    # object — Flipper passes its internal wrapper to group procs, which breaks
    # is_a?/class checks, so this facade unwraps it for you:
    #
    #   FeatureFlag.define_segment(:admins) { |actor| actor.is_a?(AdminUser) }
    def define_segment(name, &block)
      Flipper.register(name) do |actor, context|
        raw = actor.respond_to?(:actor) ? actor.actor : actor

        block.arity == 1 ? block.call(raw) : block.call(raw, context)
      end
    end
  end
end
