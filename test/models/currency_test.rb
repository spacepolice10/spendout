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
    currency = budgets(:active).currencies.build(alphabetic_code: " eur ")

    assert currency.valid?
    assert_equal "EUR", currency.alphabetic_code
    assert_equal "Euro", currency.name
    assert_equal "978", currency.numeric_code
    assert_equal "€", currency.symbol
  end

  test "rejects unknown currency codes" do
    currency = budgets(:active).currencies.build(alphabetic_code: "ZZZ")

    assert_not currency.valid?
    assert currency.errors.added?(:alphabetic_code, :inclusion, value: "ZZZ")
    assert_nil currency.name
  end

  test "requires unique codes within a budget" do
    duplicate = budgets(:active).currencies.build(alphabetic_code: "USD")

    assert_not duplicate.valid?
    assert duplicate.errors.added?(:alphabetic_code, :taken, value: "USD")
  end

  test "options use the public label and code shape" do
    assert_includes Currency.options, [ "US Dollar (USD)", "USD" ]
  end
end
