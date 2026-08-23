require "application_system_test_case"

class CurrencyPickerTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit new_budget_source_path(budgets(:active))

    find("details", text: "Currency:").find("summary").click
  end

  test "shows popular currencies before filtering" do
    assert_button "USD US Dollar, 🇺🇸"
    assert_button "EUR Euro, 🇪🇺"
    assert_button "GBP Pound Sterling, 🇬🇧"
    assert_no_button "VND Dong, 🇻🇳"
    assert_no_selector "[data-currency-picker-target='emptyState']:not([hidden])"
  end

  test "filters by code and name replacing the popular list" do
    filter.set("yen")
    assert_button "JPY Yen, 🇯🇵"
    assert_no_button "USD US Dollar, 🇺🇸"

    filter.set("vnd")
    assert_button "VND Dong, 🇻🇳"

    filter.set("usd")
    assert_button "USD US Dollar, 🇺🇸"

    filter.set("zzzz")
    assert_text "No currencies found"

    filter.set("")
    assert_button "EUR Euro, 🇪🇺"
    assert_no_button "VND Dong, 🇻🇳"
    assert_no_selector "[data-currency-picker-target='emptyState']:not([hidden])"
  end

  test "choosing a currency updates selection summary and rate fields without closing" do
    filter.set("dong")

    click_button "VND Dong, 🇻🇳"

    assert_equal "VND", find("select[name='source[currency_code]']", visible: :all).value
    assert_selector "details[open]"
    assert_selector "summary small", text: "VND"
    assert_selector "button[value='VND'][data-intent='primary']"
    assert_selector "[data-currency-conversion-target='rateFields']:not([hidden])"

    rate = find("input[name='source[rate]']")
    send_input(rate, "26600")

    assert_equal "26.600", rate.value
    assert_text(/=\s*\$1(?:\.00)?/)
  end

  private
    def filter
      find("input[data-currency-picker-target='filter']")
    end

    def send_input(field, value)
      page.execute_script(<<~JAVASCRIPT, field, value)
        const input = arguments[0]
        input.value = arguments[1]
        input.setSelectionRange(input.value.length, input.value.length)
        input.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertText" }))
      JAVASCRIPT
    end
end
