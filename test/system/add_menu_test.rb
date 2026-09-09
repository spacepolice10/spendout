require "application_system_test_case"

class AddMenuTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit budget_lenses_path(budgets(:active))
  end

  test "income and expense buttons are visible on the lenses page" do
    within "nav[aria-label='Add'] > div" do
      assert_link "Income", href: new_budget_income_path(budgets(:active))
      assert_link "Expense", href: new_budget_expense_path(budgets(:active))
    end
  end

  test "add button is absent from expenses and forms" do
    visit budget_expenses_path(budgets(:active))
    assert_no_selector "nav[aria-label='Add']"

    visit new_budget_expense_path(budgets(:active))
    assert_no_selector "nav[aria-label='Add']"
  end

  test "quick add buttons open their creation forms" do
    click_on "Income"
    assert_current_path new_budget_income_path(budgets(:active))

    visit budget_lenses_path(budgets(:active))
    click_on "Expense"
    assert_current_path new_budget_expense_path(budgets(:active))
  end

  test "add button is absent when signed out" do
    sign_out
    visit new_session_path

    assert_no_selector "nav[aria-label='Add']"
  end
end
