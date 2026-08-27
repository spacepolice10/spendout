require "test_helper"

class ExchangeTest < ActiveSupport::TestCase
  setup do
    @budget = budgets(:active)
    @sender = sources(:active)
  end

  test "creates a receiver source and snapshots an exchange" do
    original_balance = @sender.spendable_amount
    exchange = build_exchange(sender_amount: "100.2500", rate: "0.8")

    assert_difference [ "Exchange.count", "Source.count" ], 1 do
      assert exchange.save_with_receiver_source
    end

    assert_equal BigDecimal("80.2"), exchange.receiver_amount
    assert_equal BigDecimal("80.2"), exchange.receiver_source.amount
    assert_equal BigDecimal("0.8"), exchange.receiver_source.rate
    assert_equal "USD", exchange.sender_source.currency_code
    assert_equal "EUR", exchange.receiver_source.currency_code
    assert_equal original_balance - BigDecimal("100.25"), @sender.reload.spendable_amount
  end

  test "rounds the generated source to money precision" do
    exchange = build_exchange(sender_amount: "1.0000", rate: "0.333333333333")

    assert exchange.save_with_receiver_source
    assert_equal BigDecimal("0.3333"), exchange.receiver_amount
    assert_equal exchange.receiver_amount, exchange.receiver_source.amount
  end

  test "rejects an exchange exceeding the sender balance without creating either record" do
    available = @sender.spendable_amount
    exchange = build_exchange(sender_amount: available + BigDecimal("0.0001"))

    assert_no_difference [ "Exchange.count", "Source.count" ] do
      assert_not exchange.save_with_receiver_source
    end
    assert exchange.errors.added?(:sender_amount, "must be less than or equal to #{available.to_s("F")}")
  end

  test "expenses and exchanges share sender capacity" do
    @budget.expenses.create!(source: @sender, amount: @sender.spendable_amount - BigDecimal("0.25"), occurred_on: Date.current)
    exchange = build_exchange(sender_amount: "1")

    assert_not exchange.save_with_receiver_source
    assert exchange.errors.added?(:sender_amount, "must be less than or equal to 0.25")
  end

  test "allows the same currency and rejects a deleted sender" do
    same_currency = build_exchange(receiver_currency_code: "USD", rate: "0.9")
    assert same_currency.save_with_receiver_source
    assert_equal BigDecimal("90"), same_currency.receiver_source.amount

    @sender.update!(deleted_at: Time.current)
    deleted_parent = build_exchange
    assert_not deleted_parent.save_with_receiver_source
    assert deleted_parent.errors.added?(:sender_source, "must be active")
  end

  test "cannot be updated or destroyed directly" do
    exchange = build_exchange
    assert exchange.save_with_receiver_source

    assert_not exchange.update(sender_amount: 1)
    assert_not exchange.destroy
    assert exchange.persisted?
  end

  test "does not change budget source value when quotes are consistent" do
    original_total = @budget.sources_amount_in_base
    exchange = build_exchange(sender_amount: "100", rate: "0.8")

    assert exchange.save_with_receiver_source
    assert_equal original_total, @budget.reload.sources_amount_in_base
  end

  test "uses the mandatory unit quote when exchanging back to the budget base currency" do
    euro_sender = @budget.sources.create!(name: "Euro", amount: 100, currency_code: "EUR", rate: "0.8")
    exchange = euro_sender.outgoing_exchanges.new(
      budget: @budget, receiver_source_name: "Dollars", receiver_currency_code: "USD",
      sender_amount: "80", rate: "1.25"
    )

    assert exchange.save_with_receiver_source
    assert_equal BigDecimal("100"), exchange.receiver_source.amount
    assert_equal BigDecimal("1"), exchange.receiver_source.rate
  end

  test "is removed with its whole budget" do
    exchange = build_exchange
    assert exchange.save_with_receiver_source
    archived_budget = budgets(:archived)
    archived_sender = sources(:archived)
    archived_exchange = archived_sender.outgoing_exchanges.new(
      budget: archived_budget, receiver_source_name: "Dollars", receiver_currency_code: "USD",
      sender_amount: "10", rate: "1.2"
    )
    assert archived_exchange.save_with_receiver_source

    assert_difference("Exchange.count", -1) { archived_budget.destroy! }
  end

  private
    def build_exchange(sender_amount: "100", rate: "0.8", receiver_currency_code: "EUR")
      @sender.outgoing_exchanges.new(
        budget: @budget,
        receiver_source_name: "Euro cash",
        receiver_currency_code: receiver_currency_code,
        sender_amount: sender_amount,
        rate: rate
      )
    end
end
