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
      click_on "Categories"
    end
    assert_current_path budget_allocations_path(budgets(:active))

    within "nav[aria-label='Budget sections']" do
      assert_selector "a[aria-current='page']", text: "Categories"
    end
  end

  test "tabbar is absent when signed out" do
    sign_out
    visit new_session_path

    assert_no_selector "nav[aria-label='Budget sections']"
  end
end
