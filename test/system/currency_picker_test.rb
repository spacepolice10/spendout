require "application_system_test_case"

class CurrencyPickerTest < ApplicationSystemTestCase
  setup do
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
    sign_in_as users(:one)
    visit new_budget_source_path(budgets(:active))
    find("details[data-amount-currency-section]").find("summary").click
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

  test "keeps the compact currency trigger narrower than the amount field" do
    layout = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const amount = document.querySelector("[data-amount-currency-row] > input")
        const trigger = document.querySelector("[data-amount-currency-row] [data-currency-picker-target='currencyTrigger']")
        const selection = trigger.querySelector("[data-currency-picker-target='selection']")
        const chevron = trigger.querySelector(".icon-wrap")

        return {
          display: getComputedStyle(trigger).display,
          amountWidth: amount.getBoundingClientRect().width,
          triggerWidth: trigger.getBoundingClientRect().width,
          selectionBottom: selection.getBoundingClientRect().bottom,
          chevronTop: chevron.getBoundingClientRect().top
        }
      })()
    JAVASCRIPT

    assert_equal "grid", layout["display"]
    assert_operator layout["triggerWidth"], :<, layout["amountWidth"]
    assert_operator layout["chevronTop"], :>=, layout["selectionBottom"]
  end

  test "selects a currency, closes the dialog, and restores trigger focus" do
    choose_currency("dong", "VND Dong, 🇻🇳")

    assert_equal "VND", hidden_currency.value
    assert_no_selector currency_dialog("[open]")
    assert_selector "button[data-currency-picker-target='currencyTrigger']:focus"
    assert_selector "button[data-currency-picker-target='currencyTrigger']", text: "🇻🇳 VND"
    assert_selector "[data-controller~='currency-rate-picker']:not([hidden])"
  end

  test "selects the active filtered currency with Enter and closes the dialog" do
    open_currency
    filter.set("dong")
    filter.send_keys(:enter)

    assert_equal "VND", hidden_currency.value
    assert_no_selector currency_dialog("[open]")
    assert_selector "button[data-currency-picker-target='currencyTrigger']:focus"
  end

  test "Enter stays inside the dialog when no currency matches" do
    open_currency
    filter.set("zzzz")
    filter.send_keys(:enter)

    assert_selector currency_dialog("[open]")
    assert_selector "input[data-currency-picker-target='filter']:focus"
    assert_text "No currencies found"
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

  test "autofills a reference quote and allows inline editing" do
    Rails.cache.write(CurrencyReference::CACHE_KEY, {
      "reference_date" => Date.current.iso8601,
      "rates" => { "EUR" => "1", "USD" => "1.2", "VND" => "30000" }
    })
    visit new_budget_source_path(budgets(:active))
    find("details[data-amount-currency-section]").find("summary").click
    choose_currency("dong", "VND Dong, 🇻🇳")

    assert_equal "25.000", rate.value
    send_input(rate, "24950")

    assert_equal "24.950", rate.value
  end

  test "offers manual entry when no reference quote exists" do
    choose_currency("dong", "VND Dong, 🇻🇳")

    assert_equal "", rate.value
    assert_equal "Enter rate", rate["placeholder"]
    assert_selector "label", text: "Enter how many units of VND are in 1 USD"
    assert_selector "input[name='source[rate]']"
  end

  test "same-currency selection hides the rate trigger and normalizes rate" do
    choose_currency("dong", "VND Dong, 🇻🇳")
    choose_currency("dollar", "USD US Dollar, 🇺🇸")

    assert_selector "[data-controller~='currency-rate-picker'][hidden]", visible: :all
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

    def currency_dialog(suffix = "")
      "dialog[data-currency-picker-target='currencyDialog']#{suffix}"
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
