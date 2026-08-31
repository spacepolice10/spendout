require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
  end

  test "requires authentication" do
    get budget_report_path(@budget)

    assert_redirected_to new_session_path
  end

  test "shows summary metrics and spending breakdowns" do
    sign_in_as(@user)

    get budget_report_path(@budget)

    assert_response :success
    assert_select "[data-testid='most-expensive-category']", text: /Housing/
    assert_select "[data-report-summary] > article", count: 6
    assert_select "[data-testid='report-total-spent']", text: /125/
    assert_select "[data-testid='report-everyday-average']"
    assert_select "[data-testid='report-largest-expense']", text: /125/
    assert_select "[data-testid='report-transaction-number']", text: /1/
    assert_select "[data-testid='report-general-sources']", text: /1,200.25/
    assert_select "[data-testid='spending-by-date'] [data-spending-calendar]", count: 1
    assert_select "[data-spending-calendar] [role='columnheader']", count: 7
    assert_select "[data-spending-calendar] [data-calendar-date]", count: (@budget.starts_date..@budget.ends_date).count
    assert_select "[data-spending-calendar] progress", count: 0
    assert_select "[data-testid='spending-by-category'] progress", count: 1
    assert_select "[data-testid='spending-by-category'] [data-report-section]" do
      assert_select "header > .icon-wrap + strong", text: /Housing/
      assert_select "[data-report-category-total]", text: /125.*1 expense/
      assert_select "[data-report-category-total] + progress", count: 1
    end
    assert_select "[data-testid='allocations-vs-expenses']", count: 0
    assert_select "nav[aria-label='Budget sections'] a", text: /Reports|User/, count: 0
    assert_select "nav[data-navigation-layout='rail']"
    assert_select "dialog#budget-menu[data-turbo-temporary]", count: 0
  end

  test "shows the mobile tabbar for mobile user agents" do
    sign_in_as(@user)

    get budget_report_path(@budget), headers: { "User-Agent" => "Mozilla/5.0 (iPhone) Mobile" }

    assert_response :success
    assert_select "nav[aria-label='Budget sections']"
    assert_select "nav[aria-label='Budget sections'] > div > a", count: 3
    assert_select "dialog#budget-menu[data-turbo-temporary]", count: 0
  end

  test "marks removed and finished categories with compact badges" do
    sign_in_as(@user)
    allocation = allocations(:active)

    allocation.update!(finished_at: Time.current)
    get budget_report_path(@budget)

    assert_select "[data-report-category-status='finished'][aria-label='Finished'][title='Finished']", text: "F", count: 2
    assert_select "[data-report-category-status='removed']", count: 0

    allocation.update!(finished_at: nil, deleted_at: Time.current)
    get budget_report_path(@budget)

    assert_select "[data-report-category-status='removed'][aria-label='Removed'][title='Removed']", text: "R", count: 2
    assert_select "[data-report-category-status='finished']", count: 0
    assert_select "[data-testid='budget-report']", text: /\(Deleted\)|\(Finished\)/, count: 0
  end

  test "does not expose another user's report" do
    sign_in_as(users(:two))

    get budget_report_path(@budget)

    assert_response :not_found
  end
end
