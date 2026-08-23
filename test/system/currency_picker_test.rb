require "application_system_test_case"

class CurrencyPickerTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit new_budget_source_path(budgets(:active))

    find("details", text: /currency:/i).find("summary").click
  end

  test "shows popular currencies before filtering" do
    assert_visible_option "USD US Dollar, 🇺🇸"
    assert_visible_option "EUR Euro, 🇪🇺"
    assert_visible_option "GBP Pound Sterling, 🇬🇧"
    assert_no_visible_option "VND Dong, 🇻🇳"
    assert_no_selector "[data-currency-picker-target='emptyState']:not([hidden])"
  end

  test "filters by code and name replacing the popular list" do
    filter.set("yen")
    assert_visible_option "JPY Yen, 🇯🇵"
    assert_no_visible_option "USD US Dollar, 🇺🇸"

    filter.set("vnd")
    assert_visible_option "VND Dong, 🇻🇳"

    filter.set("usd")
    assert_visible_option "USD US Dollar, 🇺🇸"

    filter.set("zzzz")
    assert_text "No currencies found"

    filter.set("")
    assert_visible_option "EUR Euro, 🇪🇺"
    assert_no_visible_option "VND Dong, 🇻🇳"
    assert_no_selector "[data-currency-picker-target='emptyState']:not([hidden])"
  end

  test "shows at most seven options at once" do
    filter.set("a")

    assert_selector visible_options, count: 4
  end

  test "choosing a currency updates selection summary and rate fields without closing" do
    filter.set("dong")

    find(visible_option, text: "VND Dong, 🇻🇳").click

    assert_equal "VND", find("select[name='source[currency_code]']", visible: :all).value
    assert find("input[type='radio'][value='VND']", visible: :all).checked?
    assert_selector "details[open]"
    assert_selector "[data-currency-conversion-target='rateFields']:not([hidden])"
    assert_selector "[data-currency-conversion-target='rateCode']", text: "VND"

    rate = find("input[name='source[rate]']")
    send_input(rate, "26600")
    send_input(find("input[name='source[amount]']"), "26600")

    assert_equal "1", find("[data-currency-conversion-target='converted']").value

    # The summary value preview is only shown once the details is collapsed.
    find("details", text: /currency:/i).find("summary").click
    assert_selector "summary small", text: "VND"
  end

  private
    def filter
      find("input[data-currency-picker-target='filter']")
    end

    def visible_option
      "label[data-currency-picker-target='option']:not([hidden])"
    end

    def visible_options
      visible_option
    end

    def assert_visible_option(text)
      assert_selector visible_option, text: text
    end

    def assert_no_visible_option(text)
      assert_no_selector visible_option, text: text
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
