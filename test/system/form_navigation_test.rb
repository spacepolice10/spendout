require "application_system_test_case"

class FormNavigationTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit new_budget_source_path(budgets(:active))
  end

  test "tab moves between form inputs in document order" do
    find("input[name='source[name]']").send_keys(:tab)

    assert_selector "input[name='source[amount]']:focus"
  end
end
