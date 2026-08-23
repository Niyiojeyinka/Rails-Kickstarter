# frozen_string_literal: true

# Feature flag management inside ActiveAdmin.
#
# The native page below lists every flag with its gates and a one-click
# on/off toggle (backed by the FeatureFlags::Toggler component). The full
# Flipper UI is mounted at /admin/flipper behind the same admin auth for
# advanced gate configuration (percentage rolls, actors, groups).
ActiveAdmin.register_page "Feature Flags" do
  menu priority: 2, label: "Feature Flags"

  content title: "Feature Flags" do
    render partial: "admin/feature_flags/index", locals: { features: Flipper.features.sort_by(&:name) }
  end

  page_action :toggle, method: :post do
    result = FeatureFlags::Toggler.call(params[:feature])

    if result.success?
      redirect_back fallback_location: admin_feature_flags_path,
        notice: "Feature updated."
    else
      redirect_back fallback_location: admin_feature_flags_path,
        alert: result.error
    end
  end
end
