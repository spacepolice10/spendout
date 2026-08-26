require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "root redirects to the current budget" do
    get root_path

    assert_redirected_to budget_expenses_path(budgets(:active))
  end

  test "root redirects to budget creation when all budgets are archived" do
    budgets(:active).update_columns(period_to: Date.yesterday)

    get root_path

    assert_redirected_to new_budget_path
  end

  test "new redirects to the current budget when one exists" do
    get new_budget_path

    assert_redirected_to budget_expenses_path(budgets(:active))
  end

  test "reset permanently deletes the budget and its contents" do
    budget = budgets(:active)
    counts = {
      budgets: Budget.count,
      sources: Source.count,
      allocations: Allocation.count,
      expenses: Expense.count,
      budget_sources: budget.sources.size,
      budget_allocations: budget.allocations.size,
      budget_expenses: budget.expenses.size
    }

    delete budget_path(budget)

    assert_redirected_to new_budget_path
    assert_equal counts[:budgets] - 1, Budget.count
    assert_equal counts[:sources] - counts[:budget_sources], Source.count
    assert_equal counts[:allocations] - counts[:budget_allocations], Allocation.count
    assert_equal counts[:expenses] - counts[:budget_expenses], Expense.count
  end

  test "cannot reset another user's budget" do
    assert_no_difference([ "Budget.count", "Source.count", "Allocation.count", "Expense.count" ]) do
      delete budget_path(budgets(:other))
    end

    assert_response :not_found
  end

  test "new renders when all budgets are archived" do
    budgets(:active).update_columns(period_to: Date.yesterday)

    get new_budget_path

    assert_response :success
    assert_select "h1", "New budget"
    assert_select "select[name='budget[base_currency_code]'][data-currency-picker-target='select']"
    assert_select "input[type='search'][placeholder='Search by name or code'][data-currency-picker-target='filter']"
    assert_select "input[data-currency-picker-target='filter'][autofocus]"
    assert_select "label[data-currency-picker-target='option'][data-filter-value='USD US Dollar, 🇺🇸']:not([hidden])"
    assert_select "dialog[data-currency-picker-target='currencyDialog'][aria-labelledby]"
    assert_select "button[data-currency-picker-target='currencyTrigger'][aria-haspopup='dialog']"
    assert_select "label[data-currency-picker-target='option']:not([hidden])", count: Currency.options.size
    assert_select "[data-currency-picker-target='emptyState'][hidden]"
    assert_select "input[name='budget[source_amount]']", count: 0
    assert_select "input[name='budget[source_rate]']", count: 0
    assert_select "form legend", text: "When does your budget start and end?"
    assert_select "form input[type='date'][name='budget[starts_date]'][required]"
    assert_select "form input[type='date'][name='budget[ends_date]'][required]"
  end

  test "new includes the timezone currency without selecting it" do
    budgets(:active).update_columns(period_to: Date.yesterday)
    cookies[:timezone] = "Asia/Saigon"

    get new_budget_path

    assert_response :success
    assert_select "select[name='budget[base_currency_code]'] option[selected]", count: 0
    assert_select "label[data-currency-picker-target='option'][data-suggested='true'][data-filter-value='VND Dong, 🇻🇳']:not([hidden])" do
      assert_select "input[value='VND']:not([checked])"
    end
    assert_select "label[data-currency-picker-target='option']:not([hidden])", count: Currency.options.size
  end

  test "new does not autofocus the currency picker on mobile devices" do
    budgets(:active).update_columns(period_to: Date.yesterday)

    get new_budget_path, headers: {
      "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148"
    }

    assert_response :success
    assert_select "[data-currency-picker-autofocus-value='false']"
    assert_select "form input[autofocus]", count: 0
  end

  test "new does not duplicate a popular timezone currency" do
    budgets(:active).update_columns(period_to: Date.yesterday)
    cookies[:timezone] = "America/New_York"

    get new_budget_path

    assert_response :success
    assert_select "label[data-currency-picker-target='option'][data-filter-value='USD US Dollar, 🇺🇸']", count: 1
    assert_select "label[data-currency-picker-target='option']:not([hidden])", count: Currency.options.size
  end

  test "creating a budget without a source redirects to source creation" do
    budgets(:active).update_columns(period_to: Date.yesterday)

    assert_difference("Budget.count", 1) do
      assert_no_difference("Source.count") do
        post budgets_path, params: { budget: {
          starts_date: Date.current,
          ends_date: Date.current + 29.days,
          base_currency_code: "USD"
        } }
      end
    end

    assert_redirected_to budget_sources_path(Budget.order(:id).last)
  end

  test "cannot create another active budget" do
    assert_no_difference("Budget.count") do
      post budgets_path, params: { budget: {
        starts_date: Date.current,
        ends_date: Date.current + 29.days,
        base_currency_code: "USD"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "li", "An active budget already exists"
  end
end
