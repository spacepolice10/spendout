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

  test "opens a native dialog with every currency and filters it" do
    open_currency

    assert_selector currency_dialog("[open]")
    assert_selector visible_options, count: Currency.options.size, visible: :all
    assert_selector "input[data-currency-picker-target='filter']:focus"

    filter.set("dong")
    assert_visible_option "VND Dong, 🇻🇳"
    assert_no_visible_option "USD US Dollar, 🇺🇸"

    filter.set("zzzz")
    assert_text "No currencies found"
  end

  test "selects a currency, closes the dialog, and restores trigger focus" do
    choose_currency("dong", "VND Dong, 🇻🇳")

    assert_equal "VND", hidden_currency.value
    assert_no_selector currency_dialog("[open]")
    assert_selector "button[data-currency-picker-target='currencyTrigger']:focus"
    assert_selector "button[data-currency-picker-target='currencyTrigger']", text: "VND Dong, 🇻🇳"
    assert_selector "[data-currency-picker-target='attachment']:not([hidden])"
  end

  test "selects the active filtered currency with Enter and closes the dialog" do
    open_currency
    filter.set("dong")
    filter.send_keys(:enter)

    assert_equal "VND", hidden_currency.value
    assert_no_selector currency_dialog("[open]")
    assert_selector "button[data-currency-picker-target='currencyTrigger']:focus"
  end

  test "moves through currencies with arrow keys and closes after keyboard selection" do
    open_currency
    expected_code = all("[data-currency-picker-option] input", visible: :all)[1].value

    filter.send_keys(:arrow_down)
    assert_selector "label[data-currency-picker-active] input[value='#{expected_code}']", visible: :all
    assert_equal filter["aria-activedescendant"],
      find("label[data-currency-picker-active]", visible: :all)["id"]
    filter.send_keys(:enter)

    assert_equal expected_code, hidden_currency.value
    assert_no_selector currency_dialog("[open]")
    assert_selector "button[data-currency-picker-target='currencyTrigger']:focus"
  end

  test "Escape closes currency selection without changing it" do
    open_currency
    filter.set("dong")
    filter.send_keys(:escape)

    assert_equal "USD", hidden_currency.value
    assert_no_selector currency_dialog("[open]")
    assert_selector "button[data-currency-picker-target='currencyTrigger']:focus"
  end

  test "autofills a reference quote and applies an edited rate" do
    Rails.cache.write(CurrencyReference::CACHE_KEY, {
      "reference_date" => Date.current.iso8601,
      "rates" => { "EUR" => "1", "USD" => "1.2", "VND" => "30000" }
    })
    visit new_budget_source_path(budgets(:active))
    find("details", text: /currency:/i).find("summary").click
    choose_currency("dong", "VND Dong, 🇻🇳")

    assert_selector rate_trigger, text: "1 USD = 25.000 VND"
    find(rate_trigger).click
    assert_selector rate_dialog("[open]")
    send_input(rate, "24950")
    click_button "Apply"

    assert_no_selector rate_dialog("[open]")
    assert_selector rate_trigger, text: "1 USD = 24.950 VND"
    assert_equal "24.950", rate.value
  end

  test "the dialog close button restores the confirmed rate" do
    choose_currency("dong", "VND Dong, 🇻🇳")
    find(rate_trigger).click
    send_input(rate, "25000")
    click_button "Apply"

    find(rate_trigger).click
    send_input(rate, "26000")
    find("button[aria-label='Cancel rate changes']").click

    assert_equal "25.000", rate.value
    assert_selector rate_trigger, text: "1 USD = 25.000 VND"
  end

  test "offers manual entry when no reference quote exists" do
    choose_currency("dong", "VND Dong, 🇻🇳")

    assert_selector rate_trigger, text: "Enter rate"
    find(rate_trigger).click
    assert_selector "input[name='source[rate]']:focus"
    within rate_dialog("[open]") do
      assert_selector "label", text: "Enter how many units of VND are in 1 USD"
      assert_selector "input[name='source[rate]']"
      assert_selector "button[data-appearance='keycap']", text: "Apply"
      assert_no_selector "small, output"
    end
  end

  test "same-currency selection hides the rate trigger and normalizes rate" do
    choose_currency("dong", "VND Dong, 🇻🇳")
    choose_currency("dollar", "USD US Dollar, 🇺🇸")

    assert_selector "[data-currency-picker-target='attachment'][hidden]", visible: :all
    assert_equal "1", rate.value
  end

  test "invalid required currency opens its dialog" do
    budgets(:active).update_columns(period_to: Date.yesterday)
    visit new_budget_path
    find(currency_dialog("[open]")).send_keys(:escape)

    click_button "Next step"

    assert_selector currency_dialog("[open]")
    assert_selector "input[data-currency-picker-target='filter']:focus"
  end

  private
    def open_currency
      find("button[data-currency-picker-target='currencyTrigger']").click
    end

    def choose_currency(query, label)
      open_currency
      filter.set(query)
      find(visible_option, text: label).click
    end

    def filter
      find("input[data-currency-picker-target='filter']")
    end

    def hidden_currency
      find("select[name='source[currency_code]']", visible: :all)
    end

    def rate
      find("input[name='source[rate]']", visible: :all)
    end

    def rate_trigger
      "button[data-currency-picker-target='rateTrigger']"
    end

    def currency_dialog(suffix = "")
      "dialog[data-currency-picker-target='currencyDialog']#{suffix}"
    end

    def rate_dialog(suffix = "")
      "dialog[data-currency-picker-target='rateDialog']#{suffix}"
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
