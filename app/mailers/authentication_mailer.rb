class AuthenticationMailer < ApplicationMailer
  def sign_in_instructions(email_address:, code:)
    @code = code
    mail to: email_address, subject: "Your Spendout code is #{code}"
  end
end
