require "test_helper"

class RecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    sign_in_as(@user)
  end

  test "html visits redirect to the dashboard timeline" do
    get budget_records_path(@budget)

    assert_redirected_to budget_lenses_path(@budget)
  end

  test "next page continues the timeline in the matching turbo frame" do
    15.times do |index|
      @budget.expenses.create!(source: sources(:active), category: categories(:active), amount: 1,
        occurred_on: @budget.period_from + index.days, note: "Expense #{index}")
    end

    get budget_lenses_path(@budget)
    next_href = css_select("a[data-testid='records-load-more']").first["href"]

    get next_href, headers: { "Turbo-Frame" => "records-pagination-contents-2" }

    assert_response :success
    assert_select "turbo-frame#records-pagination-contents-2 [data-testid='expense-card']", count: 1
    assert_select "a[data-testid='records-load-more']", count: 0
  end

  test "does not expose another user's records" do
    get budget_records_path(budgets(:other))
    assert_response :not_found
  end
end
