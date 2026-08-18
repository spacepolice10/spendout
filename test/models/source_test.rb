require "test_helper"

class SourceTest < ActiveSupport::TestCase
  test "allows zero and preserves four decimal places" do
    source = budgets(:active).sources.build(amount: "0.1234", currency_code: "USD")

    assert source.valid?
    assert_equal BigDecimal("0.1234"), source.amount
    assert_equal "Main source", source.name
    assert_equal "wallet", source.icon
    assert_equal "hotpink", source.colour
  end

  test "rejects negative amounts" do
    source = budgets(:active).sources.build(amount: -0.0001, currency_code: "USD")

    assert_not source.valid?
    assert source.errors.added?(:amount, :greater_than_or_equal_to, value: BigDecimal("-0.0001"), count: 0)
  end

  test "reports deletion without hiding the record" do
    source = sources(:active)
    source.update!(deleted_at: Time.current)

    assert source.deleted?
    assert_equal source, Source.find(source.id)
  end

  test "resolves currency horizontally within its budget" do
    assert_equal currencies(:active_usd), sources(:active).currency
  end

  test "rejects a currency that is not available in its budget" do
    source = budgets(:active).sources.build(amount: 1, currency_code: "EUR")

    assert_not source.valid?
    assert source.errors.added?(:currency_code, "must be available in this budget")
  end
end
