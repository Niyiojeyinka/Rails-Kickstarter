class ApplicationController < ActionController::Base
  around_action :switch_locale

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def default_url_options
    return super unless params[:locale].present?

    super.merge(locale: I18n.locale)
  end

  private

  def switch_locale(&action)
    I18n.with_locale(requested_locale) do
      response.set_header("Content-Language", I18n.locale.to_s)
      action.call
    end
  end

  def requested_locale
    requested_locales.find { |locale| I18n.available_locales.include?(locale) } || I18n.default_locale
  end

  def requested_locales
    [ params[:locale], *accepted_locales ]
      .compact_blank
      .map { |locale| locale.to_s.split("-").first.downcase.to_sym }
  end

  def accepted_locales
    request.headers["Accept-Language"].to_s.split(",")
      .sort_by { |entry| -(entry[/;\s*q=([0-9.]+)/i, 1] || 1).to_f }
      .map { |entry| entry.split(";").first.strip }
  end
end
