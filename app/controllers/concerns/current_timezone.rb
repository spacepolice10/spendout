module CurrentTimezone
  extend ActiveSupport::Concern

  included do
    around_action :set_current_timezone

    helper_method :timezone_from_cookie

    etag { timezone_from_cookie }
  end

  private
    def set_current_timezone(&)
      Current.timezone = timezone_from_cookie
      Current.suggested_currency_code = Currency.of_timezone(Current.timezone&.tzinfo&.identifier)

      Time.use_zone(Current.timezone || Time.zone_default, &)
    end

    def timezone_from_cookie
      @timezone_from_cookie ||= begin
        timezone = cookies[:timezone]
        ActiveSupport::TimeZone[timezone] if timezone.present?
      end
    end
end
