require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @administrator = users(:one)
    @member = users(:two)
  end

  test "listing users as an administrator" do
    sign_in_as(@administrator)

    get admin_users_path

    assert_response :success
    assert_select "li", text: /one@example.com/
    assert_select "li", text: /two@example.com/
  end

  test "adding a user with a password" do
    sign_in_as(@administrator)

    assert_difference("User.count", 1) do
      assert_enqueued_emails 0 do
        post admin_users_path, params: {
          user: {
            email_address: "person@example.com",
            password: "correct horse battery staple",
            password_confirmation: "correct horse battery staple"
          }
        }
      end
    end

    user = User.find_by!(email_address: "person@example.com")
    assert user.member?
    assert user.authenticate("correct horse battery staple")
    assert_redirected_to admin_users_path
  end

  test "adding a user with an initial sign-in code" do
    sign_in_as(@administrator)

    assert_difference([ "User.count", "AuthCode.count" ], 1) do
      assert_enqueued_emails 1 do
        post admin_users_path, params: {
          user: {
            email_address: "person@example.com",
            password: "",
            password_confirmation: ""
          }
        }
      end
    end

    user = User.find_by!(email_address: "person@example.com")
    assert user.member?
    assert_not user.password_digest?
    assert_redirected_to admin_users_path
  end

  test "rejecting invalid user details" do
    sign_in_as(@administrator)

    assert_no_difference("User.count") do
      post admin_users_path, params: {
        user: {
          email_address: "invalid",
          password: "short",
          password_confirmation: "short"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "requiring email delivery for a code-only user" do
    sign_in_as(@administrator)
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    assert_no_difference([ "User.count", "AuthCode.count" ]) do
      post admin_users_path, params: {
        user: {
          email_address: "person@example.com",
          password: "",
          password_confirmation: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "p", text: /Configure email delivery/
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
  end

  test "rejecting a member" do
    sign_in_as(@member)

    get admin_users_path

    assert_redirected_to root_path
    assert_equal "Administrator access is required.", flash[:alert]
  end
end
