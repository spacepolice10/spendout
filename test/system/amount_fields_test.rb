require "application_system_test_case"

class AmountFieldsTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit new_budget_expense_path(budgets(:active))
  end

  test "formats grouped and fractional amounts while typing" do
    amount = find("input[name='expense[amount]']")

    input_value(amount, "1000")
    assert_equal "1.000", amount.value

    input_value(amount, "2000000")
    assert_equal "2.000.000", amount.value

    input_value(amount, "1234,5600")
    assert_equal "1.234,5600", amount.value
  end

  test "accepts canonical and localized pasted values" do
    amount = find("input[name='expense[amount]']")

    paste_value(amount, "1234.56")
    assert_equal "1.234,56", amount.value

    page.execute_script("arguments[0].select()", amount)
    paste_value(amount, "1.234,5600")
    assert_equal "1.234,5600", amount.value
  end

  test "preserves the caret when grouping changes around a middle edit" do
    amount = find("input[name='expense[amount]']")
    input_value(amount, "1234")

    caret = page.evaluate_script(<<~JAVASCRIPT, amount)
      (() => {
        const input = arguments[0]
        input.setSelectionRange(1, 1)
        input.setRangeText("9", 1, 1, "end")
        input.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertText", data: "9" }))
        return input.selectionStart
      })()
    JAVASCRIPT

    assert_equal "19.234", amount.value
    assert_equal 2, caret
  end

  test "enforces amount boundaries and four fractional digits" do
    amount = find("input[name='expense[amount]']")

    input_value(amount, "0")
    assert_not field_valid?(amount)

    input_value(amount, "-1")
    assert_not field_valid?(amount)

    input_value(amount, "1,23456")
    assert_equal "1,2345", amount.value
    assert field_valid?(amount)

    input_value(amount, "")
    assert_not field_valid?(amount)
  end

  test "allows zero for a source balance" do
    visit new_budget_source_path(budgets(:active))
    amount = find("input[name='source[amount]']", visible: :all)

    input_value(amount, "0")

    assert field_valid?(amount)
  end

  test "requires conversion rates to be greater than zero" do
    visit new_budget_source_path(budgets(:active))
    find("details", text: /currency:/i).find("summary").click
    find("button[data-currency-picker-target='currencyTrigger']").click
    find("input[data-currency-picker-target='filter']").set("vnd")
    find("label[data-currency-picker-target='option']:not([hidden])", text: "VND Dong, 🇻🇳").click
    find("button[data-currency-picker-target='rateTrigger']").click
    rate = find("input[name='source[rate]']")

    input_value(rate, "0")
    assert_not field_valid?(rate)

    input_value(rate, "0,000000000001")
    assert field_valid?(rate)
  end

  test "submits a canonical decimal without changing the localized display" do
    amount = find("input[name='expense[amount]']")
    input_value(amount, "1234,5600")

    assert_difference -> { budgets(:active).expenses.count }, 1 do
      click_button "Confirm"
      assert_text "Expenses"
    end

    assert_equal BigDecimal("1234.5600"), budgets(:active).expenses.order(:created_at, :id).last.amount
  end

  test "formats the amount again after a validation rerender" do
    amount = find("input[name='expense[amount]']")
    input_value(amount, "1375,2501")

    click_button "Confirm"

    assert_text "Amount must be less than or equal to"
    assert_equal "1.375,2501", find("input[name='expense[amount]']").value
  end

  test "keeps long values at the base type size" do
    amount = find("input[name='expense[amount]']")
    sizes = page.evaluate_script(<<~JAVASCRIPT, amount)
      (() => {
        const input = arguments[0]
        const normal = parseFloat(getComputedStyle(input).fontSize)
        input.style.width = "12rem"
        input.value = "999999999999999"
        input.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertText" }))
        const current = parseFloat(getComputedStyle(input).fontSize)
        return { normal, current }
      })()
    JAVASCRIPT

    assert_in_delta sizes["normal"], sizes["current"], 0.25
    assert_operator sizes["current"], :>=, 16
  end

  test "formats a rate without showing a real-time conversion" do
    visit new_budget_source_path(budgets(:active))

    find("details", text: /currency:/i).find("summary").click
    find("button[data-currency-picker-target='currencyTrigger']").click
    find("input[data-currency-picker-target='filter']").set("vnd")
    find("label[data-currency-picker-target='option']:not([hidden])", text: "VND Dong, 🇻🇳").click

    input_value(find("input[name='source[amount]']", visible: :all), "52000")

    find("button[data-currency-picker-target='rateTrigger']").click
    rate = find("input[name='source[rate]']")
    input_value(rate, "26000")

    assert_equal "26.000", rate.value
    assert_no_selector "[data-currency-fields-target='converted']", visible: :all
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

    def paste_value(field, value)
      page.execute_script(<<~JAVASCRIPT, field, value)
        const input = arguments[0]
        const transfer = new DataTransfer()
        transfer.setData("text", arguments[1])
        input.dispatchEvent(new ClipboardEvent("paste", { bubbles: true, cancelable: true, clipboardData: transfer }))
      JAVASCRIPT
    end

    def field_valid?(field)
      page.evaluate_script("arguments[0].checkValidity()", field)
    end
end
