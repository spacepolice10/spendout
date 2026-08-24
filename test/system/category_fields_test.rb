require "application_system_test_case"

class ExpenseCategoryFieldsTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit new_budget_expense_path(budgets(:active))

    find("details[data-controller~='category-fields']").find("summary").click
  end

  test "filters allocations and stages typed text as a new category" do
    filter = find("#expense_category_filter")

    filter.set("Hous")
    within("fieldset[data-expense-allocations]") do
      assert_text "Housing"
      assert_text "Category named Hous will be created"
    end
    assert_equal "Hous", find("input[name='expense[category_name_to_create]']", visible: :all).value
    assert_no_selector "input[name='expense[allocation_id]']:checked", visible: :all

    find("label[data-category-fields-target='option']", text: "Housing").click
    assert_equal "", find("input[name='expense[category_name_to_create]']", visible: :all).value
    assert_no_text "will be created"
    assert_selector "input[name='expense[allocation_id]']:checked", visible: :all

    filter.set("Coffee")
    within("fieldset[data-expense-allocations]") do
      assert_no_text "Housing"
      assert_text "Category named Coffee will be created"
      assert_no_button
    end
    assert_equal "Coffee", find("input[name='expense[category_name_to_create]']", visible: :all).value
    assert_selector "details[open] fieldset[data-expense-allocations]"

    filter.set("")
    assert_equal "", find("input[name='expense[category_name_to_create]']", visible: :all).value
    assert_no_text "will be created"
    assert_text "Housing"
  end

  test "stages a category when the budget has no allocations" do
    budgets(:active).allocations.update_all(deleted_at: Time.current)

    visit new_budget_expense_path(budgets(:active))
    find("details[data-controller~='category-fields']").find("summary").click

    within("fieldset[data-expense-allocations]") do
      assert_field "Find or add category", with: ""
      assert_no_text "will be created"
    end

    find("#expense_category_filter").set("Coffee")

    assert_text "Category named Coffee will be created"
    assert_equal "Coffee", find("input[name='expense[category_name_to_create]']", visible: :all).value
  end
end
