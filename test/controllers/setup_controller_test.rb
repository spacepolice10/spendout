require "test_helper"

class SetupControllerTest < ActionDispatch::IntegrationTest
  setup do
    User.destroy_all
  end

  test "showing setup for an empty installation" do
    get new_setup_path

    assert_response :success
    assert_select "h1", "Set up Spendout"
  end

  test "creating the first administrator" do
    assert_difference("User.count", 1) do
      post setup_path, params: {
        user: {
          email_address: " OWNER@Example.com ",
          password: "correct horse battery staple",
          password_confirmation: "correct horse battery staple"
        }
      }
    end

    administrator = User.sole
    assert administrator.administrator?
    assert_equal "owner@example.com", administrator.email_address
    assert administrator.authenticate("correct horse battery staple")
    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "rejecting an invalid administrator" do
    assert_no_difference("User.count") do
      post setup_path, params: {
        user: {
          email_address: "owner@example.com",
          password: "short",
          password_confirmation: "short"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "redirecting setup after installation" do
    User.create!(email_address: "owner@example.com")

    get new_setup_path

    assert_redirected_to new_session_path
  end
end
