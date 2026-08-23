class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Every model can act as a Flipper actor, so feature flags can be enabled
  # per record out of the box:
  #
  #   FeatureFlag.enable_for(:new_checkout, user)
  #   FeatureFlag.enabled_for?(:new_checkout, user)
  #
  # (Actor ids look like "AdminUser;1" — gate persisted records, not new ones.)
  include Flipper::Identifier
end
