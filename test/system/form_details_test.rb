require "application_system_test_case"

class FormDetailsTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit new_budget_source_path(budgets(:active))
  end

  test "enter moves between form details inputs" do
    name = find("input[name='source[name]']")
    name.fill_in with: "Cash"
    name.send_keys(:enter)

    assert_selector "details[open] input[name='source[amount]']:focus"

    find("input[name='source[amount]']").send_keys([ :shift, :enter ])

    assert_selector "details[open] input[name='source[name]']:focus"
  end

  test "enter does not advance past an invalid input" do
    find("input[name='source[name]']").send_keys(:enter)

    assert_selector "details[open] input[name='source[name]']:focus"
  end

  test "enter moves through expense details" do
    visit new_budget_expense_path(budgets(:active))

    amount = find("input[name='expense[amount]']")
    amount.fill_in with: "10"
    amount.send_keys(:enter)

    assert_selector "details[open] input[name='expense[source_id]']:focus"

    find("input[name='expense[source_id]']:focus").send_keys(:enter)

    assert_selector "details[open] #expense_category_filter:focus"
  end
end
