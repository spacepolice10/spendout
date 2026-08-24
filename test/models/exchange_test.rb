require "test_helper"

class ExchangeTest < ActiveSupport::TestCase
  setup do
    @budget = budgets(:active)
    @parent = sources(:active)
  end

  test "creates a child source and snapshots an exchange" do
    original_balance = @parent.spendable_amount
    exchange = build_exchange(parent_amount: "100.2500", rate: "0.8")

    assert_difference [ "Exchange.count", "Source.count" ], 1 do
      assert exchange.save_with_child_source
    end

    assert_equal BigDecimal("80.2"), exchange.child_amount
    assert_equal BigDecimal("80.2"), exchange.child_source.amount
    assert_equal BigDecimal("0.8"), exchange.child_source.rate
    assert_equal "USD", exchange.parent_currency_code
    assert_equal "EUR", exchange.child_currency_code
    assert_equal original_balance - BigDecimal("100.25"), @parent.reload.spendable_amount
  end

  test "rounds the generated source to money precision" do
    exchange = build_exchange(parent_amount: "1.0000", rate: "0.333333333333")

    assert exchange.save_with_child_source
    assert_equal BigDecimal("0.3333"), exchange.child_amount
    assert_equal exchange.child_amount, exchange.child_source.amount
  end

  test "rejects an exchange exceeding the parent balance without creating either record" do
    available = @parent.spendable_amount
    exchange = build_exchange(parent_amount: available + BigDecimal("0.0001"))

    assert_no_difference [ "Exchange.count", "Source.count" ] do
      assert_not exchange.save_with_child_source
    end
    assert exchange.errors.added?(:parent_amount, "must be less than or equal to #{available.to_s("F")}")
  end

  test "expenses and exchanges share parent capacity" do
    @budget.expenses.create!(source: @parent, amount: @parent.spendable_amount - BigDecimal("0.25"), occurred_on: Date.current)
    exchange = build_exchange(parent_amount: "1")

    assert_not exchange.save_with_child_source
    assert exchange.errors.added?(:parent_amount, "must be less than or equal to 0.25")
  end

  test "rejects the same currency and a deleted parent" do
    same_currency = build_exchange(child_currency_code: "USD")
    assert_not same_currency.save_with_child_source
    assert same_currency.errors.added?(:child_currency_code, "must differ from the parent currency")

    @parent.update!(deleted_at: Time.current)
    deleted_parent = build_exchange
    assert_not deleted_parent.save_with_child_source
    assert deleted_parent.errors.added?(:parent_source, "must be active")
  end

  test "cannot be updated or destroyed directly" do
    exchange = build_exchange
    assert exchange.save_with_child_source

    assert_not exchange.update(parent_amount: 1)
    assert_not exchange.destroy
    assert exchange.persisted?
  end

  test "does not change budget source value when quotes are consistent" do
    original_total = @budget.sources_amount_in_base
    exchange = build_exchange(parent_amount: "100", rate: "0.8")

    assert exchange.save_with_child_source
    assert_equal original_total, @budget.reload.sources_amount_in_base
  end

  test "uses the mandatory unit quote when exchanging back to the budget base currency" do
    euro_parent = @budget.sources.create!(name: "Euro", amount: 100, currency_code: "EUR", rate: "0.8")
    exchange = euro_parent.outgoing_exchanges.new(
      budget: @budget, child_source_name: "Dollars", child_currency_code: "USD",
      parent_amount: "80", rate: "1.25"
    )

    assert exchange.save_with_child_source
    assert_equal BigDecimal("100"), exchange.child_source.amount
    assert_equal BigDecimal("1"), exchange.child_source.rate
  end

  test "is removed with its whole budget" do
    exchange = build_exchange
    assert exchange.save_with_child_source
    archived_budget = budgets(:archived)
    archived_parent = sources(:archived)
    archived_exchange = archived_parent.outgoing_exchanges.new(
      budget: archived_budget, child_source_name: "Dollars", child_currency_code: "USD",
      parent_amount: "10", rate: "1.2"
    )
    assert archived_exchange.save_with_child_source

    assert_difference("Exchange.count", -1) { archived_budget.destroy! }
  end

  private
    def build_exchange(parent_amount: "100", rate: "0.8", child_currency_code: "EUR")
      @parent.outgoing_exchanges.new(
        budget: @budget,
        child_source_name: "Euro cash",
        child_currency_code: child_currency_code,
        parent_amount: parent_amount,
        rate: rate
      )
    end
end
