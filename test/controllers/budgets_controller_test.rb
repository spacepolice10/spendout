require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "requires authentication" do
    get budgets_path

    assert_redirected_to new_session_path
  end

  test "index lists active budgets before faded archived budgets" do
    sign_in_as(@user)

    travel_to Date.new(2026, 8, 18) do
      get budgets_path
    end

    assert_response :success
    assert_select "[data-testid='budget-card']", count: 2
    assert_select "[data-testid='budget-link']:first-of-type [data-archived='false']"
    assert_select "[data-testid='budget-card'][data-archived='true']", text: /Archived/
    assert_select "a[aria-label='New budget'][href='#{new_budget_path}']"
  end

  test "new builds only code and amount form fields" do
    sign_in_as(@user)

    get new_budget_path

    assert_response :success
    assert_select "select[name='budget[currency_code]'] option[value='USD']"
    assert_select "fieldset.salary legend", text: "What's your salary?"
    assert_select "input[name='budget[source_amount]'][aria-label='Enter your salary amount']"
    assert_select "select[name='budget[currency_code]'][aria-label='Choose your salary currency']"
    assert_select "input[name*='[name]']", count: 0
    assert_select "input[name*='[numeric_code]']", count: 0
    assert_select "input[type='radio'][value='14_days']"
    assert_select "input[type='radio'][value='30_days'][checked]"
    assert_select "fieldset legend", text: "How often do you get paid?"
    assert_select "details:not([open]) summary", text: "Change start date"
    assert_select "a[aria-label='Back to budgets'][href='#{budgets_path}']"
  end

  test "show has accessible back navigation" do
    sign_in_as(@user)

    get budget_path(budgets(:active))

    assert_response :success
    assert_select "a[aria-label='Back to budgets'][href='#{budgets_path}']"
  end

  test "creates the complete aggregate from canonical currency data" do
    sign_in_as(@user)

    assert_difference([ "Budget.count", "Currency.count", "Source.count" ], 1) do
      post budgets_path, params: budget_params(
        start: "2026-12-20",
        duration: "30_days",
        code: "all",
        amount: "123.4567",
        injected_name: "Hacked currency"
      )
    end

    budget = @user.budgets.order(:created_at).last
    assert_redirected_to budget_path(budget)
    assert_equal Date.new(2027, 1, 18), budget.period_to
    assert_equal "Lek", budget.base_currency.name
    assert_equal "008", budget.base_currency.numeric_code
    assert_equal BigDecimal("123.4567"), budget.base_source.amount
    assert_equal "ALL", budget.base_source.currency_code
  end

  test "invalid source creates no records and rerenders errors" do
    sign_in_as(@user)

    assert_no_difference([ "Budget.count", "Currency.count", "Source.count" ]) do
      post budgets_path, params: budget_params(amount: "-1")
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /must be greater than or equal to 0/
  end

  test "cannot show another user's budget" do
    sign_in_as(@user)

    get budget_path(budgets(:other))

    assert_response :not_found
  end

  test "destroys the entire budget aggregate" do
    sign_in_as(@user)
    budget = budgets(:active)

    assert_difference("Budget.count", -1) do
      assert_difference("Currency.count", -1) do
        assert_difference("Source.count", -1) do
          delete budget_path(budget)
        end
      end
    end

    assert_redirected_to budgets_path
  end

  private
    def budget_params(start: "2026-08-18", duration: "14_days", code: "USD", amount: "100", injected_name: nil)
      {
        budget: {
          period_from: start,
          duration: duration,
          currency_code: code,
          source_amount: amount,
          name: injected_name
        }
      }
    end
end
