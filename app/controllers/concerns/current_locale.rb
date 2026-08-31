module CurrentLocale
  extend ActiveSupport::Concern

  included do
    around_action :set_current_locale

    helper_method :current_locale

    etag { current_locale }
  end

  private
    def set_current_locale(&)
      I18n.with_locale(current_locale, &)
    end

    def current_locale
      @current_locale ||= locale_from_cookie || locale_from_request || I18n.default_locale
    end

    def locale_from_cookie
      locale = cookies[:locale].to_s.to_sym
      locale if I18n.available_locales.include?(locale)
    end

    def locale_from_request
      request.headers["Accept-Language"].to_s.split(",").filter_map do |preference|
        locale = preference.split(";", 2).first.to_s.strip.split("-", 2).first.to_sym
        locale if I18n.available_locales.include?(locale)
      end.first
    end
end
