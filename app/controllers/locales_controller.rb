class LocalesController < ApplicationController
  allow_unauthenticated_access

  def update
    locale = params.require(:locale).to_s
    return head :unprocessable_entity unless I18n.available_locales.map(&:to_s).include?(locale)

    cookies.permanent[:locale] = { value: locale, same_site: :lax }
    redirect_back fallback_location: root_path, status: :see_other
  end
end
