require "application_system_test_case"

class CrossCurrencyExpensesTest < ApplicationSystemTestCase
  setup do
    Rails.cache.write(CurrencyReference::CACHE_KEY, {
      "reference_date" => Date.current.iso8601,
      "rates" => { "EUR" => "1", "USD" => "1.2", "RUB" => "96", "VND" => "30720" }
    })
    @budget = budgets(:active)
    @rubles = @budget.sources.create!(name: "Rubles", amount: 50_000, currency_code: "RUB", rate: 80)
    sign_in_as users(:one)
    visit new_budget_expense_path(@budget)
  end

  teardown do
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  test "preserves purchase currency and recalculates a direct quote when the source changes" do
    input_value(find("input[name='expense[amount]']", visible: :all), "1601200")

    find("details", text: /currency:/i).find("summary").click
    find("button[data-currency-picker-target='currencyTrigger']").click
    find("input[data-currency-picker-target='filter']").set("vnd")
    find("label[data-currency-picker-target='option']:not([hidden])", text: "VND Dong, 🇻🇳").click

    assert_field "expense_conversion_rate", with: "25.600", visible: :all

    find("details", text: /from:/i).find("summary").click
    find("label", text: /Rubles/).click

    assert_equal "VND", find("select[name='expense[currency_code]']", visible: :all).value
    assert_equal "RUB", first("[data-currency-picker-option] input", visible: :all).value
    assert_field "expense_conversion_rate", with: "320", visible: :all
    find("details", text: /currency:/i).find("summary").click
    find("button[data-currency-picker-target='rateTrigger']").click
    assert_selector "input[name='expense[conversion_rate]']:focus"
    assert_no_selector "[data-expense-fields-target='sourceDebit'], [data-expense-fields-target='budgetValue']",
      visible: :all
  end

  private
    def input_value(field, value)
      page.execute_script(<<~JAVASCRIPT, field, value)
        const input = arguments[0]
        input.value = arguments[1]
        input.setSelectionRange(input.value.length, input.value.length)
        input.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertText" }))
      JAVASCRIPT
    end
end
