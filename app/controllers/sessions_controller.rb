class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: I18n.t("sessions.create.rate_limited") }

  def new
  end

  def create
    email_address = AuthCode.normalize_email_address(params[:email_address])

    if email_address.present? && email_address.match?(URI::MailTo::EMAIL_REGEXP)
      session[:email_address_pending_authentication] = email_address
      AuthCode.produce(email_address)
      redirect_to session_auth_code_path, notice: t("sessions.create.code_sent")
    else
      redirect_to new_session_path, alert: t("sessions.create.invalid_address")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
