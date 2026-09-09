require "test_helper"

class IncomesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    @source = sources(:active)
    sign_in_as(@user)
  end

  test "creates a directed income and increases its wallet balance" do
    opening = @source.spendable_amount

    assert_difference("Income.count", 1) do
      post budget_incomes_path(@budget), params: {
        income: {
          source_id: @source.id, source_name: "Client", amount: "125.50",
          currency_code: "USD", occurred_on: "2026-08-20"
        }
      }
    end

    assert_redirected_to budget_lenses_path(@budget)
    assert_equal opening + BigDecimal("125.5"), @source.reload.spendable_amount
  end

  test "new explains that a wallet must exist" do
    @budget.sources.update_all(deleted_at: Time.current)

    get new_budget_income_path(@budget)

    assert_response :success
    assert_select "a[href='#{new_budget_source_path(@budget)}']"
    assert_select "form", count: 0
  end

  test "cancel returns to lenses" do
    get new_budget_income_path(@budget)

    assert_response :success
    assert_select "a[href='#{budget_lenses_path(@budget)}'][data-action*='history#back']", text: /Cancel/
    assert_select "dialog#income-source-picker-dialog[closedby='any']"
  end

  test "new suggests what to enter for the sender and note" do
    get new_budget_income_path(@budget)

    assert_response :success
    assert_select "input[name='income[source_name]'][placeholder='Salary, client, refund…']"
    assert_select "input[name='income[note]'][placeholder='Add an optional note…']"
  end

  test "cannot use another budget's wallet" do
    assert_no_difference("Income.count") do
      post budget_incomes_path(@budget), params: {
        income: {
          source_id: sources(:other).id, source_name: "Tampered", amount: 1,
          currency_code: "VND", occurred_on: "2026-08-20"
        }
      }
    end
    assert_response :unprocessable_entity
  end
end
