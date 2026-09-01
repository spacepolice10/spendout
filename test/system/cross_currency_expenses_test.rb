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

  test "switches the purchase currency to the source currency when the source changes" do
    input_value(find("input[name='expense[amount]']", visible: :all), "1601200")

    find("button[data-currency-picker-target='currencyTrigger']").click
    find("input[data-currency-picker-target='filter']").set("vnd")
    find("label[data-currency-picker-target='option']:not([hidden])", text: "VND Dong, 🇻🇳").click

    assert_field "expense_conversion_rate", with: "25.600", visible: :all

    find("details", text: /from:/i).find("summary").click
    find("label", text: /Rubles/).click

    assert_equal "RUB", find("select[name='expense[currency_code]']", visible: :all).value
    assert_selector "input[value='RUB']:checked", visible: :all
    assert_selector "details[data-amount-currency-section] > summary", text: /Amount\s+1\.601\.200 RUB/i
    assert_field "expense_conversion_rate", with: "1", disabled: true, visible: :all
    assert_selector "[data-controller~='currency-rate-picker'][hidden]", visible: :all
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
