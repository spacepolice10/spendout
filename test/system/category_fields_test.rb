require "application_system_test_case"

class ExpenseCategoryFieldsTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit new_budget_expense_path(budgets(:active))

    find("[data-category-picker] > button").click
    assert_selector "dialog#category-picker-dialog[open][closedby='any']"
  end

  test "filters categories and confirms typed text as a new category" do
    icon_metrics = page.evaluate_script(<<~JS)
      (() => {
        const icon = document.querySelector("[data-category-picker-option] .icon")
        const style = getComputedStyle(icon)
        return { width: icon.getBoundingClientRect().width, mask: style.maskImage }
      })()
    JS
    assert_operator icon_metrics.fetch("width"), :>, 0
    assert_not_equal "none", icon_metrics.fetch("mask")

    filter = find("#expense_category_filter")

    filter.set("Hous")
    within("dialog#category-picker-dialog") do
      assert_text "Housing"
      assert_text "Category named Hous will be created"
    end
    assert_equal "", find("input[name='expense[category_name_to_create]']", visible: :all).value
    assert_selector "input[name='expense[category_id]']:checked", visible: :all

    find("label[data-category-fields-target='option']", text: "Housing").click
    assert_equal "", find("input[name='expense[category_name_to_create]']", visible: :all).value
    assert_no_text "will be created"
    assert_selector "input[name='expense[category_id]']:checked", visible: :all

    find("[data-category-picker] > button").click
    filter.set("Coffee")
    within("dialog#category-picker-dialog") do
      assert_no_text "Housing"
      assert_text "Category named Coffee will be created"
      assert_button "Confirm"
      assert_button "×"
    end
    assert_selector "dialog#category-picker-dialog[open]"

    click_button "Confirm"
    assert_equal "Coffee", find("input[name='expense[category_name_to_create]']", visible: :all).value
    assert_selector "input[name='expense[category_id]'][value='']:checked", visible: :all
    assert_no_selector "dialog#category-picker-dialog[open]"
    assert_button "Confirm"

    find("input[name='expense[amount]']").set("10")
    assert_difference [ "Category.count", "Expense.count" ], 1 do
      click_button "Confirm"
      assert_current_path budget_lenses_path(budgets(:active))
    end
  end

  test "stages a category when the budget has no active categories" do
    budgets(:active).categories.update_all(deleted_at: Time.current)

    visit new_budget_expense_path(budgets(:active))
    find("[data-category-picker] > button").click

    within("dialog#category-picker-dialog") do
      assert_field "Find or add category", with: ""
      assert_no_text "will be created"
    end

    find("#expense_category_filter").set("Coffee")

    assert_text "Category named Coffee will be created"
    click_button "Confirm"
    assert_equal "Coffee", find("input[name='expense[category_name_to_create]']", visible: :all).value
  end
end
