require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    @source = sources(:active)
    @category = categories(:active)
    @expense = expenses(:active)
  end

  test "requires authentication" do
    get new_budget_expense_path(@budget)
    assert_redirected_to new_session_path
  end

  test "index renders categorized expense history" do
    sign_in_as(@user)

    get budget_expenses_path(@budget)

    assert_response :success
    assert_select "[data-testid='expense-card']", count: 1
    assert_select "nav[aria-label='Add']", count: 0
  end

  test "index paginates expense history" do
    sign_in_as(@user)
    15.times do |index|
      @budget.expenses.create!(source: @source, category: @category, amount: 1,
        occurred_on: @budget.period_from + index.days, note: "Expense #{index}")
    end

    get budget_expenses_path(@budget)

    assert_select "[data-testid='expense-card']", count: 15
    assert_select "nav[aria-label='Pagination for expenses']", text: /Page 1 of 2/
  end

  test "new defaults source category and occurrence and renders controls" do
    sign_in_as(@user)

    travel_to Date.new(2026, 8, 20) do
      get new_budget_expense_path(@budget)

      assert_response :success
      assert_select "input[name='expense[source_id]'][value='#{@source.id}'][checked][required]"
      assert_select "input[name='expense[category_id]'][value='#{@category.id}'][checked][required]"
      assert_select "[data-category-picker-option]", count: @budget.categories.active.count
      assert_select "input[name='expense[occurred_on]'][value='2026-08-20']"
      assert_select "input[name='expense[category_name_to_create]']"
      assert_select "a[href='#{budget_lenses_path(@budget)}'][data-intent='ghost'][data-action*='history#back']", text: /Cancel/
      assert_select "button[type='submit']", text: /Confirm/
      assert_select "[data-form-actions] .icon", count: 0
    end
  end

  test "creates a categorized expense in a currency independent from its source" do
    sign_in_as(@user)

    assert_difference("Expense.count", 1) do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id, category_id: @category.id, amount: "25.2500",
          occurred_on: "2026-08-20", note: "Dinner", currency_code: "EUR",
          conversion_rate: "0.5"
        }
      }
    end

    expense = @budget.expenses.order(:created_at, :id).last
    assert_redirected_to budget_lenses_path(@budget)
    assert_equal @category, expense.category
    assert_equal BigDecimal("50.5"), expense.source_amount
    assert_equal "EUR", expense.currency_code
  end

  test "creates a category inline with an expense" do
    sign_in_as(@user)

    assert_difference([ "Expense.count", "Category.count" ], 1) do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id, category_name_to_create: "Coffee", amount: "5.25",
          occurred_on: "2026-08-20"
        }
      }
    end

    category = @budget.expenses.order(:created_at, :id).last.category
    assert_redirected_to budget_lenses_path(@budget)
    assert_equal "Coffee", category.name
    assert_nil category.allocation
    assert_equal "coffee", category.icon
  end

  test "does not leave an inline category behind when expense is invalid" do
    sign_in_as(@user)

    assert_no_difference([ "Expense.count", "Category.count" ]) do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id, category_name_to_create: "Coffee", amount: "2000",
          occurred_on: "2026-08-20"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "input[name='expense[category_name_to_create]'][value='Coffee']"
  end

  test "rejects missing and cross-budget categories" do
    sign_in_as(@user)

    assert_no_difference("Expense.count") do
      post budget_expenses_path(@budget), params: {
        expense: { source_id: @source.id, amount: "1", occurred_on: "2026-08-20" }
      }
    end
    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Category must exist/

    assert_no_difference("Expense.count") do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id, category_id: categories(:other).id,
          amount: "1", occurred_on: "2026-08-20"
        }
      }
    end
    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Category must belong to this budget/
  end

  test "records a recurrence as a normal expense and advances its due date" do
    recurring = @budget.recurrences.create!(
      name: "Internet", category: @category, amount: 30, currency_code: "USD",
      occurs_on: Date.new(2026, 8, 20), occurrence_period_in_days: 30
    )
    sign_in_as(@user)

    get new_budget_expense_path(@budget, recurrence_id: recurring.id)
    assert_select "input[name='expense[amount]'][value='30.0']"
    assert_select "input[name='expense[category_id]'][value='#{@category.id}'][checked]"

    assert_difference([ "Expense.count", "RecurringOccurrence.count" ], 1) do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id, category_id: @category.id, amount: "30",
          currency_code: "USD", occurred_on: "2026-08-20", recurrence_id: recurring.id
        }
      }
    end

    assert_equal Date.new(2026, 9, 19), recurring.reload.occurs_on
  end

  test "show displays the category and owns the delete action" do
    sign_in_as(@user)

    get expense_path(@expense)

    assert_response :success
    assert_select "a[href='#{budget_category_path(@budget, @category)}']", text: @category.name
    assert_select "form[action='#{expense_path(@expense)}']"
  end

  test "deletes an owned expense permanently" do
    sign_in_as(@user)

    assert_difference("Expense.count", -1) { delete expense_path(@expense) }

    assert_redirected_to budget_expenses_path(@budget)
    assert_equal @source.amount, @source.reload.spendable_amount
  end

  test "cannot create or delete through another user's budget" do
    sign_in_as(@user)

    post budget_expenses_path(budgets(:other)), params: {
      expense: {
        source_id: sources(:other).id, category_id: categories(:other).id,
        amount: 1, occurred_on: "2026-08-10"
      }
    }
    assert_response :not_found

    delete expense_path(expenses(:other))
    assert_response :not_found
  end
end
