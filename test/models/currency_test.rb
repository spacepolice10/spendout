require "test_helper"

class CurrencyTest < ActiveSupport::TestCase
  test "finds canonical metadata without persistence" do
    currency = Currency.find!("usd")

    assert_equal "US Dollar", currency[:name]
    assert_equal "840", currency[:numeric_code]
    assert_equal "$", currency[:symbol]
  end

  test "provides the catalog as form options" do
    assert_includes Currency.options, [ "USD US Dollar, 🇺🇸", "USD" ]
  end

  test "exposes popular currency codes" do
    assert_equal %w[USD EUR GBP], Currency::POPULAR_CODES
  end

  test "provides popular currencies as form options" do
    assert_equal [
      [ "USD US Dollar, 🇺🇸", "USD" ],
      [ "EUR Euro, 🇪🇺", "EUR" ],
      [ "GBP Pound Sterling, 🇬🇧", "GBP" ]
    ], Currency.popular_options
  end

  test "rejects an unknown code" do
    assert_nil Currency.find("XXX")
    assert_raises(ArgumentError) { Currency.find!("XXX") }
  end
end
