require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    @category = categories(:active)
    sign_in_as(@user)
  end

  test "updates a budget category" do
    patch budget_category_path(@budget, @category), params: { category: { name: "Cafés" } }
    assert_redirected_to budget_category_path(@budget, @category)
    assert_equal "Cafés", @category.reload.name
  end

  test "cancel returns to lenses" do
    get budget_category_path(@budget, @category)

    assert_response :success
    assert_select "a[href='#{budget_lenses_path(@budget)}'][data-action*='history#back']", text: /Cancel/
  end

  test "retiring a category preserves its expense and retires its flows" do
    recurring = @budget.recurrences.create!(
      name: "Rent", category: @category, amount: 100, currency_code: "USD",
      occurs_on: Date.current, occurrence_period_in_days: 30
    )

    assert_no_difference([ "Category.count", "Expense.count" ]) do
      delete budget_category_path(@budget, @category)
    end

    assert_predicate @category.reload, :deleted?
    assert_predicate allocations(:active).reload, :deleted?
    assert_not_predicate recurring.reload, :active?
  end

  test "does not expose another user's category" do
    get budget_category_path(@budget, categories(:other))
    assert_response :not_found
  end
end
