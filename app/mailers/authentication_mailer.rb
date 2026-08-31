class AuthenticationMailer < ApplicationMailer
  def sign_in_instructions(email_address:, code:)
    @code = code
    @expiration_minutes = AuthCode::EXPIRATION_TIME.in_minutes.to_i
    mail to: email_address, subject: t(".subject", code: code)
  end
end
