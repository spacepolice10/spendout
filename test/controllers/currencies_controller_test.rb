require "test_helper"

class CurrenciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    @base_currency = currencies(:active_usd)
    @foreign_currency = @budget.currencies.create!(alphabetic_code: "EUR", rate: "1.1")
  end

  test "requires authentication" do
    get budget_currencies_path(@budget)

    assert_redirected_to new_session_path
  end

  test "index lists the fixed base currency and editable foreign currencies" do
    sign_in_as(@user)

    get budget_currencies_path(@budget)

    assert_response :success
    assert_select "dt", text: /US Dollar \(USD\)/
    assert_select "small", text: "Base currency"
    assert_select "a[href='#{edit_currency_path(@base_currency)}']", count: 0
    assert_select "a[href='#{edit_currency_path(@foreign_currency)}']", text: "Edit rate"
    assert_select "a[aria-label='New currency'][href='#{new_budget_currency_path(@budget)}']"
  end

  test "new excludes currencies already in the budget and explains rate direction" do
    sign_in_as(@user)

    get new_budget_currency_path(@budget)

    assert_response :success
    assert_select "select[name='currency[alphabetic_code]'] option[value='USD']", count: 0
    assert_select "select[name='currency[alphabetic_code]'] option[value='EUR']", count: 0
    assert_select "p", text: /base-currency units per one unit/
    assert_select "p", text: /USD/
  end

  test "creates a foreign currency from canonical metadata" do
    sign_in_as(@user)

    assert_difference("Currency.count", 1) do
      post budget_currencies_path(@budget), params: {
        currency: { alphabetic_code: "gbp", rate: "1.234567890123", name: "Injected" }
      }
    end

    currency = @budget.currencies.find_by!(alphabetic_code: "GBP")
    assert_redirected_to budget_currencies_path(@budget)
    assert_equal "Pound Sterling", currency.name
    assert_equal BigDecimal("1.234567890123"), currency.rate
  end

  test "rejects duplicate and invalid rates" do
    sign_in_as(@user)

    assert_no_difference("Currency.count") do
      post budget_currencies_path(@budget), params: {
        currency: { alphabetic_code: "EUR", rate: "0" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /has already been taken/
    assert_select "[role='alert']", text: /must be greater than 0/
  end

  test "edits only a foreign rate and shows its direction" do
    sign_in_as(@user)

    get edit_currency_path(@foreign_currency)

    assert_response :success
    assert_select "p", text: /1 EUR = 1.1 USD/

    patch currency_path(@foreign_currency), params: {
      currency: { alphabetic_code: "GBP", rate: "1.25" }
    }

    assert_redirected_to budget_currencies_path(@budget)
    assert_equal "EUR", @foreign_currency.reload.alphabetic_code
    assert_equal BigDecimal("1.25"), @foreign_currency.rate
  end

  test "base currency cannot be edited" do
    sign_in_as(@user)

    get edit_currency_path(@base_currency)
    assert_response :not_found

    patch currency_path(@base_currency), params: { currency: { rate: "2" } }
    assert_response :not_found
    assert_equal BigDecimal("1"), @base_currency.reload.rate
  end

  test "cannot access another user's currencies" do
    sign_in_as(@user)

    get budget_currencies_path(budgets(:other))
    assert_response :not_found

    get edit_currency_path(currencies(:other_vnd))
    assert_response :not_found
  end
end
