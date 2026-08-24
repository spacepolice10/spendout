require "application_system_test_case"

class ExchangesTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit new_source_exchange_path(sources(:active))
  end

  test "calculates the generated source amount from parent amount and rate" do
    amount = find("input[name='exchange[parent_amount]']", visible: :all)
    rate = find("input[name='exchange[rate]']", visible: :all)

    page.execute_script(<<~JAVASCRIPT, amount, rate)
      const [amount, rate] = arguments
      amount.value = "100"
      rate.value = "0,8"
      amount.dispatchEvent(new Event("input", { bubbles: true }))
      rate.dispatchEvent(new Event("input", { bubbles: true }))
    JAVASCRIPT

    assert_selector "output[data-currency-fields-target='converted']", text: "80", visible: :all
  end
end
