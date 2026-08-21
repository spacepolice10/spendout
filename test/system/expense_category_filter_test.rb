require "application_system_test_case"

class ExpenseCategoryFilterTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit new_budget_expense_path(budgets(:active))

    find("details", text: "Spend on").find("summary").click
  end

  test "filters allocations and offers to add an unmatched category" do
    filter = find("#expense_category_filter")

    filter.set("Hous")
    within("fieldset[data-expense-allocations]") do
      assert_text "Housing"
      assert_no_button "Add new"
    end

    filter.set("Coffee")
    within("fieldset[data-expense-allocations]") do
      assert_no_text "Housing"
      assert_button "Add new"
      assert_button "Cleanup"
    end

    click_button "Cleanup"
    assert_equal "", filter.value

    within("fieldset[data-expense-allocations]") do
      assert_text "Housing"
      assert_no_button "Add new"
      assert_no_button "Cleanup"
    end

    filter.set("Coffee")

    click_button "Add new"

    assert_equal "Coffee", find("input[name='expense[category_name_to_create]']", visible: :all).value
    assert_selector "[data-category-filter-target='pendingCategory']", text: "Coffee"
    assert_selector "input[type='radio'][name='expense[allocation_id]'][value='']:checked", visible: :all
    assert_no_selector "#expense_category_filter", visible: :visible
    assert_selector "details[open] fieldset[data-expense-allocations]"

    click_button "Delete"

    assert_equal "", find("input[name='expense[category_name_to_create]']", visible: :all).value
    assert_no_selector "[data-category-filter-target='pendingCategory']"
    assert_selector "#expense_category_filter", visible: :visible
    assert_equal "", filter.value
  end
end
