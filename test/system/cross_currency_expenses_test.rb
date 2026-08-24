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
    find("input[data-currency-picker-target='filter']").set("vnd")
    find("label[data-currency-picker-target='option']:not([hidden])", text: "VND Dong, 🇻🇳").click

    assert_field "expense_conversion_rate", with: "25.600", visible: :all

    find("details", text: /from:/i).find("summary").click
    find("label", text: /Rubles/).click

    assert_equal "VND", find("select[name='expense[currency_code]']", visible: :all).value
    assert_field "expense_conversion_rate", with: "320", visible: :all
    assert_equal "5003.75 RUB from Rubles",
      find("[data-expense-fields-target='sourceDebit']", visible: :all).text(:all)
    assert_equal "62.5469 USD in this budget",
      find("[data-expense-fields-target='budgetValue']", visible: :all).text(:all)

    rate = find("input[name='expense[conversion_rate]']", visible: :all)
    source_debit = find("[data-expense-fields-target='sourceDebit']", visible: :all)
    styles = page.evaluate_script(<<~JAVASCRIPT, rate, source_debit)
      ({
        rateFontSize: parseFloat(getComputedStyle(arguments[0]).fontSize),
        outputHeight: parseFloat(getComputedStyle(arguments[1]).height)
      })
    JAVASCRIPT

    assert_operator styles["rateFontSize"], :>=, 16
    assert_operator styles["outputHeight"], :>, 0

    input_value(find("input[name='expense[amount]']", visible: :all), "")
    empty_height = page.evaluate_script(
      "parseFloat(getComputedStyle(arguments[0]).height)", source_debit
    )
    assert_equal styles["outputHeight"], empty_height
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
