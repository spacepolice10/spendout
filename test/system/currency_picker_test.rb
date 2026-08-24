require "application_system_test_case"

class CurrencyPickerTest < ApplicationSystemTestCase
  setup do
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
    sign_in_as users(:one)
    visit new_budget_source_path(budgets(:active))

    find("details", text: /currency:/i).find("summary").click
  end

  teardown do
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  test "shows popular currencies before filtering" do
    filter.click
    assert_visible_option "USD US Dollar, 🇺🇸"
    assert_visible_option "EUR Euro, 🇪🇺"
    assert_visible_option "GBP Pound Sterling, 🇬🇧"
    assert_selector visible_options, maximum: 4
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
    assert_selector visible_options, maximum: 4
    assert_no_selector "[data-currency-picker-target='emptyState']:not([hidden])"
  end

  test "keeps filtered options open when the search field loses focus" do
    filter.set("dong")
    find("body").click

    assert_selector "[role='combobox'][aria-expanded='true']"
    assert_visible_option "VND Dong, 🇻🇳"

    find(visible_option, text: "VND Dong, 🇻🇳").click

    assert_equal "VND Dong, 🇻🇳", filter.value
    assert_selector "[role='combobox'][aria-expanded='false']"
  end

  test "shows at most seven options at once" do
    filter.set("a")

    assert_selector visible_options, count: 4
  end

  test "choosing a currency replaces the search text and collapses the listbox" do
    # The form sections are an accordion (shared name), so only one is open at a time.
    # Enter the amount first, then open the currency section to choose.
    find("details", text: /amount:/i).find("summary").click
    send_input(find("input[name='source[amount]']"), "26600")

    find("details", text: /currency:/i).find("summary").click
    filter.set("dong")

    find(visible_option, text: "VND Dong, 🇻🇳").click

    assert_equal "VND", find("select[name='source[currency_code]']", visible: :all).value
    assert find("input[type='radio'][value='VND']", visible: :all).checked?
    assert_equal "VND Dong, 🇻🇳", filter.value
    assert_selector "[role='combobox'][aria-expanded='false']"
    assert_selector "[role='listbox'][hidden]", visible: :all
    assert_selector "[data-currency-fields-target='rateFields']:not([hidden])"
    assert_selector ".currency-picker > [data-currency-fields-target='rateFields']"

    rate = find("input[name='source[rate]']")
    send_input(rate, "26600")
    assert_equal "1", find("[data-currency-fields-target='converted']", visible: :all).text

    # The summary value preview is only shown once the details is collapsed.
    find("details", text: /currency:/i).find("summary").click
    assert_selector "summary small", text: "VND"
  end

  test "autofills an editable reference rate" do
    Rails.cache.write(CurrencyReference::CACHE_KEY, {
      "reference_date" => Date.current.iso8601,
      "rates" => { "EUR" => "1", "USD" => "1.2", "VND" => "30000" }
    })
    visit new_budget_source_path(budgets(:active))
    find("details", text: /currency:/i).find("summary").click
    filter.set("dong")
    find(visible_option, text: "VND Dong, 🇻🇳").click

    rate = find("input[name='source[rate]']")
    assert_equal "25.000", rate.value

    send_input(rate, "24950")
    assert_equal "24.950", rate.value
  end

  test "asks for a manual rate when the selected currency has no suggestion" do
    filter.set("dong")
    find(visible_option, text: "VND Dong, 🇻🇳").click

    assert_equal "", find("input[name='source[rate]']").value
    assert_text "Reference rate unavailable. Enter a rate manually."
  end

  test "focuses the visible picker when the required currency is invalid" do
    budgets(:active).update_columns(period_to: Date.yesterday)
    visit new_budget_path

    click_button "Next step"

    assert_selector "input[data-currency-picker-target='filter']:focus"
    assert_selector "[role='combobox'][aria-expanded='true']"
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
