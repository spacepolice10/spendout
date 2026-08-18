require "test_helper"

class CurrencyTest < ActiveSupport::TestCase
  test "catalog contains current ISO metadata and is frozen" do
    assert_operator Currency.catalog.size, :>=, 170
    assert_equal({ name: "Lek", numeric_code: "008", symbol: "ALL" }, Currency.find_in_catalog("all"))
    assert_equal "CA$", Currency.find_in_catalog("CAD")[:symbol]
    assert Currency.catalog.frozen?
    assert Currency.catalog.fetch("USD").frozen?
  end

  test "normalizes a selected code and hydrates canonical metadata" do
    currency = budgets(:active).currencies.build(alphabetic_code: " eur ", rate: "1.1")

    assert currency.valid?
    assert_equal "EUR", currency.alphabetic_code
    assert_equal "Euro", currency.name
    assert_equal "978", currency.numeric_code
    assert_equal "€", currency.symbol
  end

  test "rejects unknown currency codes" do
    currency = budgets(:active).currencies.build(alphabetic_code: "ZZZ", rate: 1)

    assert_not currency.valid?
    assert currency.errors.added?(:alphabetic_code, :inclusion, value: "ZZZ")
    assert_nil currency.name
  end

  test "requires unique codes within a budget" do
    duplicate = budgets(:active).currencies.build(alphabetic_code: "USD", rate: 1)

    assert_not duplicate.valid?
    assert duplicate.errors.added?(:alphabetic_code, :taken, value: "USD")
  end

  test "options use the public label and code shape" do
    assert_includes Currency.options, [ "US Dollar (USD)", "USD" ]
  end

  test "requires a positive rate" do
    currency = budgets(:active).currencies.build(alphabetic_code: "EUR", rate: 0)

    assert_not currency.valid?
    assert currency.errors.added?(:rate, :greater_than, value: 0, count: 0)
  end

  test "stores rates with the configured precision and scale" do
    rate_column = Currency.columns_hash.fetch("rate")

    assert_equal 24, rate_column.precision
    assert_equal 12, rate_column.scale
    assert_not rate_column.null
  end

  test "database rejects a non-positive rate" do
    currency = budgets(:active).currencies.build(alphabetic_code: "EUR", rate: 0)

    assert_raises ActiveRecord::StatementInvalid do
      Currency.insert_all!([ currency.attributes.slice("budget_id", "name", "alphabetic_code", "numeric_code", "symbol", "rate") ])
    end
  end

  test "base currency rate must remain one" do
    currency = currencies(:active_usd)

    assert_not currency.update(rate: "1.01")
    assert currency.errors.added?(:rate, "must be 1 for the base currency")
    assert_equal BigDecimal("1"), currency.reload.rate
  end

  test "persisted alphabetic code is immutable" do
    currency = currencies(:active_usd)

    assert_not currency.update(alphabetic_code: "EUR")
    assert currency.errors.added?(:alphabetic_code, "cannot be changed")
    assert_equal "USD", currency.reload.alphabetic_code
  end

  test "converts without intermediate rounding" do
    currency = budgets(:active).currencies.create!(alphabetic_code: "EUR", rate: "1.123456789012")

    assert_equal BigDecimal("0.374485596336958847736996"), currency.amount_in_base(BigDecimal("0.333333333333"))
  end
end
