require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "shows the user and active budget removal action" do
    get user_path

    assert_response :success
    assert_select "h1", "User"
    assert_select "p", text: users(:one).email_address
    assert_select "form[action='#{session_path}'] button[data-appearance='keycap'][data-intent='primary']", text: "Sign out"
    assert_select "form[action='#{budget_path(budgets(:active))}'] button[data-appearance='keycap'][data-intent='negative']", text: "Remove budget"
  end

  test "does not show a budget removal action without an active budget" do
    budgets(:active).update_columns(period_to: Date.yesterday)

    get user_path

    assert_response :success
    assert_select "form[action='#{session_path}'] button[data-appearance='keycap'][data-intent='primary']", text: "Sign out"
    assert_select "button", text: "Remove budget", count: 0
  end
end
