require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    Rails.cache.clear
  end

  test "new" do
    get new_session_path

    assert_response :success
  end

  test "submitting an email stores pending authentication and sends a code" do
    assert_no_difference("User.count") do
      assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
        post session_path, params: { email_address: " NEW@Example.com " }
      end
    end

    assert_redirected_to session_auth_code_path
    assert_equal "new@example.com", AuthCode.last.email_address

    follow_redirect!
    assert_select "p", /new@example.com/
  end

  test "submitting an invalid email does not issue a code" do
    assert_no_difference([ "User.count", "AuthCode.count" ]) do
      assert_enqueued_emails 0 do
        post session_path, params: { email_address: "invalid" }
      end
    end

    assert_redirected_to new_session_path
  end

  test "signing in an existing user consumes the code" do
    post session_path, params: { email_address: @user.email_address }
    auth_code = AuthCode.last

    assert_no_difference("User.count") do
      post session_auth_code_path, params: { code: auth_code.code }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_not AuthCode.exists?(auth_code.id)
  end

  test "signing in a new email creates the user only after verification" do
    post session_path, params: { email_address: "new@example.com" }
    auth_code = AuthCode.last

    assert_difference("User.count", 1) do
      post session_auth_code_path, params: { code: auth_code.code.downcase }
    end

    assert_redirected_to root_path
    assert_equal "new@example.com", User.order(:created_at).last.email_address
    assert cookies[:session_id]
  end

  test "an invalid code does not create a user or session" do
    post session_path, params: { email_address: "new@example.com" }

    assert_no_difference("User.count") do
      post session_auth_code_path, params: { code: "WRONG1" }
    end

    assert_redirected_to session_auth_code_path
    assert_nil cookies[:session_id]
  end

  test "an expired code does not create a user or session" do
    travel_to Time.zone.local(2026, 8, 18, 12) do
      post session_path, params: { email_address: "new@example.com" }
      auth_code = AuthCode.last
      travel AuthCode::EXPIRATION_TIME + 1.second

      assert_no_difference("User.count") do
        post session_auth_code_path, params: { code: auth_code.code }
      end

      assert_redirected_to session_auth_code_path
      assert_nil cookies[:session_id]
    end
  end

  test "code entry requires a pending email address" do
    get session_auth_code_path

    assert_redirected_to new_session_path
  end

  test "email requests are limited to ten within three minutes" do
    10.times do
      post session_path, params: { email_address: "person@example.com" }
      assert_redirected_to session_auth_code_path
    end

    post session_path, params: { email_address: "person@example.com" }

    assert_redirected_to new_session_path
    assert_equal "Try again later.", flash[:alert]
  end

  test "code attempts are limited to ten within fifteen minutes" do
    post session_path, params: { email_address: "person@example.com" }

    10.times do
      post session_auth_code_path, params: { code: "WRONG1" }
      assert_redirected_to session_auth_code_path
    end

    post session_auth_code_path, params: { code: "WRONG1" }

    assert_redirected_to session_auth_code_path
    assert_equal "Try again in 15 minutes.", flash[:alert]
  end

  test "destroy" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
