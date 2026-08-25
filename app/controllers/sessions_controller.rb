class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
    redirect_to new_setup_path unless User.exists?
  end

  def create
    email_address = AuthCode.normalize_email_address(params[:email_address])

    if params[:authentication_method] == "password"
      authenticate_with_password(email_address)
    else
      authenticate_with_code(email_address)
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private
    def authenticate_with_password(email_address)
      if user = User.authenticate_by(email_address: email_address, password: params[:password])
        start_new_session_for(user)
        redirect_to after_authentication_url
      else
        redirect_to new_session_path, alert: "That email address or password is not correct."
      end
    end

    def authenticate_with_code(email_address)
      unless email_address.present? && email_address.match?(URI::MailTo::EMAIL_REGEXP)
        return redirect_to new_session_path, alert: "Enter a valid email address."
      end

      session[:email_address_pending_authentication] = email_address
      AuthCode.produce(email_address) if User.exists?(email_address: email_address)
      redirect_to session_auth_code_path, notice: "If that account exists, a sign-in code is on its way."
    end
end
