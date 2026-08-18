require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a valid email address" do
    assert_not User.new(email_address: "not-an-email").valid?
    assert_not User.new(email_address: nil).valid?
  end

  test "requires a unique email address regardless of case" do
    user = User.new(email_address: " ONE@EXAMPLE.COM ")

    assert_not user.valid?
    assert user.errors.added?(:email_address, :taken, value: "one@example.com")
  end
end
