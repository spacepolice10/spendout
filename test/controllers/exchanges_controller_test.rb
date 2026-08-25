require "test_helper"

class ExchangesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    @parent = sources(:active)
  end

  test "requires authentication" do
    get new_source_exchange_path(@parent)

    assert_redirected_to new_session_path
  end

  test "new renders a parent-relative exchange form" do
    sign_in_as(@user)

    get new_source_exchange_path(@parent)

    assert_response :success
    assert_select "h1", text: /Exchange from #{@parent.name}/
    assert_select "h1 a", count: 0
    assert_select "form[data-controller~='form'][data-controller~='currency-fields'][data-currency-fields-operation-value='multiply'][action='#{source_exchanges_path(@parent)}']"
    assert_select "form[data-controller~='currency-fields'][data-currency-fields-reference-url-value='#{currency_reference_path}']"
    assert_select "input[name='exchange[child_source_name]'][required][value='#{@parent.name} exchange']"
    assert_select "input[name='exchange[parent_amount]'][data-currency-fields-target='amount']"
    assert_select "select[name='exchange[child_currency_code]'][data-currency-fields-target='currency']"
    assert_select "input[name='exchange[rate]'][data-currency-fields-target='rate']"
    assert_select "output[data-currency-fields-target='converted']", count: 0
    assert_select "[data-currency-fields-target='rateStatus']", count: 0
    assert_select "dialog[data-currency-picker-target='rateDialog'] button[data-appearance='keycap']", text: "Apply"
  end

  test "creates an exchange and its generated source" do
    sign_in_as(@user)
    original_balance = @parent.spendable_amount

    assert_difference [ "Exchange.count", "Source.count" ], 1 do
      post source_exchanges_path(@parent), params: { exchange: {
        child_source_name: "Euro cash",
        child_currency_code: "EUR",
        parent_amount: "100",
        rate: "0.8",
        child_amount: "999999"
      } }
    end

    exchange = Exchange.order(:id).last
    assert_redirected_to budget_sources_path(@budget)
    assert_equal BigDecimal("80"), exchange.child_amount
    assert_equal "Euro cash", exchange.child_source.name
    assert_equal original_balance - BigDecimal("100"), @parent.reload.spendable_amount
  end

  test "invalid exchange creates neither record and rerenders errors" do
    sign_in_as(@user)
    available = @parent.spendable_amount

    assert_no_difference [ "Exchange.count", "Source.count" ] do
      post source_exchanges_path(@parent), params: { exchange: {
        child_source_name: "",
        child_currency_code: "USD",
        parent_amount: available + 1,
        rate: "1"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /must differ from the parent currency/
    assert_select "[role='alert']", text: /must be less than or equal to #{Regexp.escape(available.to_s("F"))}/
  end

  test "cannot access another user's source" do
    sign_in_as(@user)

    get new_source_exchange_path(sources(:other))

    assert_response :not_found
  end

  test "cannot exchange from a deleted source" do
    sign_in_as(@user)
    @parent.update!(deleted_at: Time.current)

    get new_source_exchange_path(@parent)

    assert_response :not_found
  end

  test "source index shows balances and immutable exchange history" do
    sign_in_as(@user)
    original_balance = @parent.spendable_amount
    exchange = @parent.outgoing_exchanges.new(
      budget: @budget, child_source_name: "Euro cash", child_currency_code: "EUR",
      parent_amount: "100", rate: "0.8"
    )
    assert exchange.save_with_child_source

    get budget_sources_path(@budget)

    assert_response :success
    assert_select "a[href='#{new_source_exchange_path(@parent)}']", text: /Exchange/
    displayed_balance = ApplicationController.helpers.formatted_amount(original_balance - 100, @parent.currency_code)
    assert_select "[data-testid='source-card']", text: /#{Regexp.escape(displayed_balance)}/
    assert_select "[data-testid='exchange-list']", count: 1
    assert_select "[data-testid='exchange-day']", count: 1
    assert_select "[data-testid='exchange-day'] time[datetime='#{exchange.created_at.to_date.iso8601}']"
    assert_select "[data-testid='exchange-history-item']", count: 1
    assert_select "[data-testid='exchange-history-item']", text: /Main source.*Euro cash/m
    assert_select "[data-testid='exchange-history-item']", text: /100.*USD.*80.*EUR/m
    assert_select "[data-testid='exchange-history-item'] a, [data-testid='exchange-history-item'] button", count: 0
  end
end
