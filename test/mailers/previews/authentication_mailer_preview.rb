class AuthenticationMailerPreview < ActionMailer::Preview
  def sign_in_instructions
    AuthenticationMailer.sign_in_instructions(
      email_address: "person@example.com",
      code: "ABC123"
    )
  end
end
