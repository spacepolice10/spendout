require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "shows the user and active budget removal action" do
    get user_path

    assert_response :success
    assert_select "h1", "User"
    assert_select "p", text: users(:one).email_address
    assert_select "h2", text: "Language"
    assert_select "p", text: "Choose the language Spendout uses."
    assert_select "[data-language-settings] > nav form[action='#{locale_path}']", count: 2
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

  test "renders in the locale selected before authentication" do
    cookies[:locale] = "ru"

    get user_path

    assert_response :success
    assert_select "h1", text: "Пользователь"
    assert_select "h2", text: "Язык"
    assert_select "form[action='#{locale_path}'] button[disabled]", text: "Русский"
  end
end
