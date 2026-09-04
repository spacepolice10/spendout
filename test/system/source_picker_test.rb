require "application_system_test_case"

class ExpenseSourcePickerTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    @budget = budgets(:active)
    @cash = @budget.sources.create!(name: "Cash", amount: 75, currency_code: "EUR", rate: "0.8")
    visit new_budget_expense_path(@budget)
  end

  test "chooses a source from the dialog and updates the expense currency context" do
    find("[data-source-picker] > button").click

    within("dialog#source-picker-dialog") do
      assert_text sources(:active).name
      assert_text "Cash"
      assert_selector "[data-source-picker-option] [data-source-design]", count: 2
      find("label[data-source-picker-target='option']", text: "Cash").click
    end

    assert_no_selector "dialog#source-picker-dialog[open]"
    within("[data-source-picker] > button") do
      assert_text "FROM:"
      assert_text "CASH"
    end
    assert_selector "input[name='expense[source_id]'][value='#{@cash.id}']:checked", visible: :all
    assert_selector "select[name='expense[currency_code]'] option[value='EUR']:checked", visible: :all
  end
end
