require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "shows the user and active budget removal action" do
    get user_path

    assert_response :success
    assert_select "header nav a[href='#{budget_lenses_path(budgets(:active))}'][data-intent='ghost'][data-action*='history#back'][aria-label='Back to dashboard']"
    assert_select "h1", "User"
    assert_select "p", text: users(:one).email_address
    assert_select "h2", text: "Language"
    assert_select "p", text: "Choose the language Spendout uses."
    assert_select "[data-language-settings] > nav[data-pill-group] form[action='#{locale_path}']", count: 2
    assert_select "[data-language-settings] button[aria-pressed='true'][disabled]", text: "English"
    assert_select "footer nav[data-pill-group] form[action='#{session_path}'] button[data-intent='primary']", text: "Sign out"
    assert_select "footer nav[data-pill-group] form[action='#{budget_path(budgets(:active))}'] button[data-intent='negative']", text: "Remove budget"
  end

  test "does not show a budget removal action without an active budget" do
    budgets(:active).update_columns(period_to: Date.yesterday)

    get user_path

    assert_response :success
    assert_select "header nav a[href='#{root_path}'][data-intent='ghost'][data-action*='history#back'][aria-label='Back to dashboard']"
    assert_select "footer nav[data-pill-group] form[action='#{session_path}'] button[data-intent='primary']", text: "Sign out"
    assert_select "button", text: "Remove budget", count: 0
  end

  test "renders in the locale selected before authentication" do
    cookies[:locale] = "ru"

    get user_path

    assert_response :success
    assert_select "h1", text: "Пользователь"
    assert_select "header nav a[aria-label='Назад к дашборду']"
    assert_select "h2", text: "Язык"
    assert_select "form[action='#{locale_path}'] button[disabled][aria-pressed='true']", text: "Русский"
  end
end
