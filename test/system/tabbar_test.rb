require "application_system_test_case"

class TabbarTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit budget_expenses_path(budgets(:active))
  end

  test "tabbar is visible on the budget pages" do
    assert_selector "nav[aria-label='Budget sections']"
  end

  test "Expenses tab is active on the expense index page" do
    within "nav[aria-label='Budget sections']" do
      assert_selector "a[aria-current='page']", text: "Expenses"
      assert_no_selector "a[aria-current='page']", text: "My money"
    end
  end

  test "switching tabs navigates and marks the active tab" do
    within "nav[aria-label='Budget sections']" do
      click_on "My money"
    end
    assert_current_path budget_sources_path(budgets(:active))

    within "nav[aria-label='Budget sections']" do
      assert_selector "a[aria-current='page']", text: "My money"
    end

    within "nav[aria-label='Budget sections']" do
      click_on "Plan"
    end
    assert_current_path budget_allocations_path(budgets(:active))

    within "nav[aria-label='Budget sections']" do
      assert_selector "a[aria-current='page']", text: "Plan"
    end
  end

  test "Cybercat opens the user page" do
    find("a[aria-label='User']").click
    assert_current_path user_path
    assert_selector "h1", text: "User"
  end

  test "desktop rail opens the user page and marks it active" do
    within "nav[aria-label='Budget sections']" do
      click_on "User"
    end

    assert_current_path user_path
    within "nav[aria-label='Budget sections']" do
      assert_selector "a[aria-current='page']", text: "User"
    end
  end

  test "desktop rail opens reports and marks it active" do
    within "nav[aria-label='Budget sections']" do
      click_on "Reports"
    end

    assert_current_path budget_report_path(budgets(:active))
    within "nav[aria-label='Budget sections']" do
      assert_selector "a[aria-current='page']", text: "Reports"
    end
  end

  test "tabbar is absent when signed out" do
    sign_out
    visit new_session_path

    assert_no_selector "nav[aria-label='Budget sections']"
  end
end
