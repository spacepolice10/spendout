class Sessions::AuthCodesController < ApplicationController
  RATE_LIMIT_WINDOW = 15.minutes

  allow_unauthenticated_access
  before_action :require_pending_email_address
  rate_limit to: 10, within: RATE_LIMIT_WINDOW, only: :create,
    with: -> {
      redirect_to session_auth_code_path,
        alert: I18n.t("sessions.auth_codes.create.rate_limited", count: RATE_LIMIT_WINDOW.in_minutes.to_i)
    }

  def show
  end

  def create
    if email_address = AuthCode.consume(params[:code], email_address: pending_email_address)
      user = User.find_or_create_by!(email_address: email_address)
      clear_pending_email_address
      start_new_session_for(user)
      redirect_to after_authentication_url
    else
      redirect_to session_auth_code_path, alert: t("sessions.auth_codes.create.invalid_code")
    end
  end

  private
    def pending_email_address
      session[:email_address_pending_authentication]
    end

    def require_pending_email_address
      unless pending_email_address.present?
        redirect_to new_session_path, alert: t("sessions.auth_codes.create.missing_email")
      end
    end

    def clear_pending_email_address
      session.delete(:email_address_pending_authentication)
    end
end
