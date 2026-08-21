require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "root redirects to the current budget" do
    get root_path

    assert_redirected_to budget_path(budgets(:active))
  end

  test "root redirects to budget creation when all budgets are archived" do
    budgets(:active).update_columns(period_to: Date.yesterday)

    get root_path

    assert_redirected_to new_budget_path
  end

  test "new redirects to the current budget when one exists" do
    get new_budget_path

    assert_redirected_to budget_path(budgets(:active))
  end

  test "show renders the expense history without currency management" do
    get budget_path(budgets(:active))

    assert_response :success
    assert_select "[data-testid='expense-card']", count: 1
    assert_select "a[href='#{new_budget_expense_path(budgets(:active))}']"
    assert_select "a", text: "Currencies", count: 0
  end

  test "new renders when all budgets are archived" do
    budgets(:active).update_columns(period_to: Date.yesterday)

    get new_budget_path

    assert_response :success
    assert_select "h1", "New budget"
    assert_select "form details > summary > span", text: "Change start date"
    assert_select "form details > summary > span > .icon-wrap"
    assert_select "form details > div input[type='date'][name='budget[period_from]']"
  end

  test "an archived budget redirects to creation when no budget is active" do
    budgets(:active).update_columns(period_to: Date.yesterday)

    get budget_path(budgets(:active))

    assert_redirected_to new_budget_path
  end

  test "creating a budget redirects directly to it" do
    budgets(:active).update_columns(period_to: Date.yesterday)

    assert_difference("Budget.count", 1) do
      post budgets_path, params: { budget: {
        period_from: Date.current,
        duration: "30_days",
        currency_code: "USD",
        source_amount: "100"
      } }
    end

    assert_redirected_to budget_path(Budget.order(:id).last)
  end

  test "cannot create another active budget" do
    assert_no_difference("Budget.count") do
      post budgets_path, params: { budget: {
        period_from: Date.current,
        duration: "30_days",
        currency_code: "USD",
        source_amount: "100"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "li", "An active budget already exists"
  end
end
