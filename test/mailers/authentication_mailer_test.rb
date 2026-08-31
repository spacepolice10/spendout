require "test_helper"

class AuthenticationMailerTest < ActionMailer::TestCase
  test "sign-in instructions localize the subject and both bodies" do
    mail = AuthenticationMailer.sign_in_instructions(
      email_address: "person@example.com",
      code: "ABC123"
    )

    assert_equal "Your Spendout code is ABC123", mail.subject
    assert_equal [ "person@example.com" ], mail.to

    [ mail.html_part, mail.text_part ].each do |part|
      body = CGI.unescapeHTML(part.body.decoded)

      assert_includes body, "Your Spendout sign-in code is:"
      assert_includes body, "ABC123"
      assert_includes body, "This code expires in 15 minutes and can only be used once."
      assert_includes body, "If you didn't request this code, you can ignore this email."
    end
  end
end
