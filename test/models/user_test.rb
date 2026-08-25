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

  test "requires an administrator to have a password" do
    user = User.new(email_address: "admin@example.com", role: :administrator)

    assert_not user.valid?
    assert user.errors.added?(:password_digest, :blank)
  end

  test "accepts a password of at least twelve characters" do
    user = User.new(
      email_address: "admin@example.com",
      role: :administrator,
      password: "twelve characters",
      password_confirmation: "twelve characters"
    )

    assert user.valid?
    assert user.authenticate("twelve characters")
  end

  test "allows a member to rely on emailed codes" do
    assert User.new(email_address: "member@example.com", role: :member).valid?
  end
end
