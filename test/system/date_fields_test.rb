require "application_system_test_case"

class DateFieldsTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    budgets(:active).update_columns(period_to: Date.yesterday)
    visit new_budget_path
  end

  test "requires the budget end date to follow its start date" do
    start_date = find("input[name='budget[starts_date]']")
    end_date = find("input[name='budget[ends_date]']")

    set_date(start_date, "2026-08-20")
    set_date(end_date, "2026-08-19")
    assert_not page.evaluate_script("arguments[0].checkValidity()", end_date)

    set_date(end_date, "2026-08-20")
    assert page.evaluate_script("arguments[0].checkValidity()", end_date)
  end

  private
    def set_date(field, value)
      page.execute_script(<<~JAVASCRIPT, field, value)
        arguments[0].value = arguments[1]
        arguments[0].dispatchEvent(new Event("input", { bubbles: true }))
        arguments[0].dispatchEvent(new Event("change", { bubbles: true }))
      JAVASCRIPT
    end
end
