class Sessions::AuthCodesController < ApplicationController
  allow_unauthenticated_access
  before_action :require_pending_email_address
  rate_limit to: 10, within: 15.minutes, only: :create,
    with: -> { redirect_to session_auth_code_path, alert: "Try again in 15 minutes." }

  def show
  end

  def create
    if email_address = AuthCode.consume(params[:code], email_address: pending_email_address)
      user = User.find_by!(email_address: email_address)
      clear_pending_email_address
      start_new_session_for(user)
      redirect_to after_authentication_url
    else
      redirect_to session_auth_code_path, alert: "Try another code."
    end
  end

  private
    def pending_email_address
      session[:email_address_pending_authentication]
    end

    def require_pending_email_address
      unless pending_email_address.present?
        redirect_to new_session_path, alert: "Enter your email address to sign in."
      end
    end

    def clear_pending_email_address
      session.delete(:email_address_pending_authentication)
    end
end
