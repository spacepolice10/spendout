require "test_helper"

class AuthCodeTest < ActiveSupport::TestCase
  test "produces a normalized six-character Base32 code that expires in 15 minutes" do
    travel_to Time.zone.local(2026, 8, 18, 12) do
      auth_code = AuthCode.produce(" PERSON@Example.COM ")

      assert_equal "person@example.com", auth_code.email_address
      assert_match(/\A[0123456789ABCDEFGHJKMNPQRSTVWXYZ]{6}\z/, auth_code.code)
      assert_equal 15.minutes.from_now, auth_code.expires_at
    end
  end

  test "producing a new code replaces the previous code for an email address" do
    previous = AuthCode.produce("person@example.com")
    current = AuthCode.produce("PERSON@example.com")

    assert_not AuthCode.exists?(previous.id)
    assert AuthCode.exists?(current.id)
  end

  test "consumes a code only once and accepts lowercase and separators" do
    auth_code = AuthCode.produce("person@example.com")
    formatted_code = auth_code.code.downcase.insert(3, "-")

    assert_equal "person@example.com", AuthCode.consume(formatted_code, email_address: " PERSON@example.com ")
    assert_nil AuthCode.consume(auth_code.code, email_address: auth_code.email_address)
  end

  test "does not consume an expired code" do
    travel_to Time.zone.local(2026, 8, 18, 12) do
      auth_code = AuthCode.create!(email_address: "person@example.com")
      travel AuthCode::EXPIRATION_TIME + 1.second

      assert_nil AuthCode.consume(auth_code.code, email_address: auth_code.email_address)
      assert AuthCode.exists?(auth_code.id)
    end
  end

  test "does not consume a code issued for another email address" do
    auth_code = AuthCode.produce("one@example.com")

    assert_nil AuthCode.consume(auth_code.code, email_address: "two@example.com")
    assert AuthCode.exists?(auth_code.id)
  end

  test "cleans up expired codes" do
    travel_to Time.zone.local(2026, 8, 18, 12) do
      expired = AuthCode.create!(email_address: "expired@example.com")
      travel AuthCode::EXPIRATION_TIME + 1.second
      active = AuthCode.create!(email_address: "active@example.com")

      assert_equal 1, AuthCode.cleanup
      assert_not AuthCode.exists?(expired.id)
      assert AuthCode.exists?(active.id)
    end
  end
end
